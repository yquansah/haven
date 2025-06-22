package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"sort"
	"sync"
	"time"
)

type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatRequest struct {
	Model       string        `json:"model"`
	Messages    []ChatMessage `json:"messages"`
	MaxTokens   int          `json:"max_tokens"`
	Temperature float64      `json:"temperature"`
}

type Usage struct {
	CompletionTokens int `json:"completion_tokens"`
	PromptTokens     int `json:"prompt_tokens"`
	TotalTokens      int `json:"total_tokens"`
}

type ChatResponse struct {
	Usage Usage `json:"usage"`
}

type RequestResult struct {
	RequestID       int     `json:"request_id"`
	Tokens          int     `json:"tokens"`
	Duration        float64 `json:"duration"`
	TokensPerSecond float64 `json:"tokens_per_second"`
}

func singleRequest(client *http.Client, baseURL, model, prompt string, maxTokens int, requestID int, wg *sync.WaitGroup, results chan<- RequestResult) {
	defer wg.Done()

	payload := ChatRequest{
		Model: model,
		Messages: []ChatMessage{
			{Role: "user", Content: prompt},
		},
		MaxTokens:   maxTokens,
		Temperature: 0.7,
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		log.Printf("Error marshaling request %d: %v", requestID, err)
		return
	}

	startTime := time.Now()

	resp, err := client.Post(baseURL+"/chat/completions", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		log.Printf("Error making request %d: %v", requestID, err)
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response %d: %v", requestID, err)
		return
	}

	var chatResp ChatResponse
	if err := json.Unmarshal(body, &chatResp); err != nil {
		log.Printf("Error unmarshaling response %d: %v", requestID, err)
		return
	}

	endTime := time.Now()
	duration := endTime.Sub(startTime).Seconds()
	tokensGenerated := chatResp.Usage.CompletionTokens
	tokensPerSecond := float64(tokensGenerated) / duration

	result := RequestResult{
		RequestID:       requestID,
		Tokens:          tokensGenerated,
		Duration:        duration,
		TokensPerSecond: tokensPerSecond,
	}

	results <- result
}

func calculateMean(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	sum := 0.0
	for _, v := range values {
		sum += v
	}
	return sum / float64(len(values))
}

func calculateMedian(values []float64) float64 {
	if len(values) == 0 {
		return 0
	}
	
	sorted := make([]float64, len(values))
	copy(sorted, values)
	sort.Float64s(sorted)
	
	n := len(sorted)
	if n%2 == 0 {
		return (sorted[n/2-1] + sorted[n/2]) / 2
	}
	return sorted[n/2]
}

func benchmarkVLLM(baseURL, model string, numRequests, maxTokens int) {
	prompt := "Write a detailed explanation about machine learning"
	
	client := &http.Client{
		Timeout: 120 * time.Second,
	}

	var wg sync.WaitGroup
	results := make(chan RequestResult, numRequests)

	// Launch goroutines for concurrent requests
	for i := range numRequests {
		wg.Add(1)
		go singleRequest(client, baseURL, model, prompt, maxTokens, i, &wg, results)
	}

	// Wait for all requests to complete
	wg.Wait()
	close(results)

	// Collect results
	var allResults []RequestResult
	for result := range results {
		allResults = append(allResults, result)
	}

	// Calculate statistics
	var tpsValues []float64
	totalTokens := 0
	maxDuration := 0.0

	for _, result := range allResults {
		tpsValues = append(tpsValues, result.TokensPerSecond)
		totalTokens += result.Tokens
		if result.Duration > maxDuration {
			maxDuration = result.Duration
		}
	}

	meanTPS := calculateMean(tpsValues)
	medianTPS := calculateMedian(tpsValues)
	totalThroughput := float64(totalTokens) / maxDuration

	fmt.Printf("Average tokens/sec per request: %.2f\n", meanTPS)
	fmt.Printf("Median tokens/sec: %.2f\n", medianTPS)
	fmt.Printf("Total throughput: %.2f tokens/sec\n", totalThroughput)
}

func main() {
	baseURL := "http://localhost:8000/v1"
	model := "TheBloke/Mistral-7B-Instruct-v0.1-GPTQ"
	numRequests := 50
	maxTokens := 512

	benchmarkVLLM(baseURL, model, numRequests, maxTokens)
}