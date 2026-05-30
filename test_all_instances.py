import requests
import urllib.parse

def test_instances():
    try:
        r = requests.get("https://searx.space/data/instances.json", timeout=10)
        if r.status_code != 200:
            print("Failed to fetch searx.space data")
            return
        
        data = r.json()
        instances = data.get("instances", {})
        
        candidates = []
        for url, info in instances.items():
            http_info = info.get("http", {})
            if http_info.get("status_code") == 200 and info.get("network_type") == "normal":
                rt = info.get("timing", {}).get("initial", {}).get("all", {}).get("value", 999.0)
                uptime = info.get("uptime", {}).get("uptimeDay", 0.0)
                candidates.append({
                    "url": url.rstrip('/'),
                    "rt": rt,
                    "uptime": uptime
                })
        
        candidates.sort(key=lambda x: (x['rt'], -x['uptime']))
        
        print(f"Testing top {min(len(candidates), 15)} candidate instances...")
        headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"}
        
        for cand in candidates[:15]:
            base_url = cand["url"]
            # Test JSON search
            try:
                test_url = f"{base_url}/search"
                res = requests.get(
                    test_url,
                    params={"q": "test", "format": "json", "categories": "general", "language": "en"},
                    headers=headers,
                    timeout=4.0
                )
                json_status = res.status_code
                json_len = 0
                if json_status == 200:
                    try:
                        json_len = len(res.json().get("results", []))
                    except:
                        json_status = "Invalid JSON"
            except Exception as e:
                json_status = f"Err: {str(e)[:20]}"
                json_len = 0
                
            # Test HTML search
            try:
                res_html = requests.get(
                    test_url,
                    params={"q": "test", "categories": "general", "language": "en"},
                    headers=headers,
                    timeout=4.0
                )
                html_status = res_html.status_code
                html_len = len(res_html.text)
            except Exception as e:
                html_status = f"Err: {str(e)[:20]}"
                html_len = 0
                
            print(f"{base_url}: rt={cand['rt']}s, uptime={cand['uptime']}% | JSON: status={json_status}, len={json_len} | HTML: status={html_status}, len={html_len}")
            
    except Exception as e:
        print(f"Error testing: {e}")

if __name__ == "__main__":
    test_instances()
