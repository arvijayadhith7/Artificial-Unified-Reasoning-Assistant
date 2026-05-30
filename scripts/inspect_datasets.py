import urllib.request

url = "https://raw.githubusercontent.com/bytewax/awesome-public-real-time-datasets/main/README.md"
try:
    with urllib.request.urlopen(url) as response:
        content = response.read().decode('utf-8')
        lines = content.split('\n')
        # Print safely to console
        for line in lines[:100]:
            print(line.encode('ascii', errors='ignore').decode('ascii'))
except Exception as e:
    print(f"Error fetching URL: {e}")
