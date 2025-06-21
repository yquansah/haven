import time
import asyncio
import aiohttp
from typing import List
import statistics

async def benchmark_vllm(
    base_url: str = "http://localhost:8000/v1",
    model: str = "TheBloke/Mistral-7B-Instruct-v0.1-GPTQ",
    num_requests: int = 50,
    max_tokens: int = 512
):
    prompt = "Write a detailed explanation about machine learning"
    
    async def single_request(session, request_id):
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": max_tokens,
            "temperature": 0.7
        }
        
        start_time = time.time()
        async with session.post(f"{base_url}/chat/completions", 
                               json=payload) as response:
            result = await response.json()
            end_time = time.time()
            
            tokens_generated = result["usage"]["completion_tokens"]
            duration = end_time - start_time
            tokens_per_second = tokens_generated / duration
            
            return {
                "request_id": request_id,
                "tokens": tokens_generated,
                "duration": duration,
                "tokens_per_second": tokens_per_second
            }
    
    async with aiohttp.ClientSession() as session:
        tasks = [single_request(session, i) for i in range(num_requests)]
        results = await asyncio.gather(*tasks)
    
    # Calculate statistics
    tps_values = [r["tokens_per_second"] for r in results]
    total_tokens = sum(r["tokens"] for r in results)
    total_time = max(r["duration"] for r in results)
    
    print(f"Average tokens/sec per request: {statistics.mean(tps_values):.2f}")
    print(f"Median tokens/sec: {statistics.median(tps_values):.2f}")
    print(f"Total throughput: {total_tokens / total_time:.2f} tokens/sec")

# Run the benchmark
asyncio.run(benchmark_vllm())
