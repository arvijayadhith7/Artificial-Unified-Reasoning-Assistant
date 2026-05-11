async function test() {
  const url = 'https://html.duckduckgo.com/html/?q=latest+news';
  try {
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36'
      }
    });
    const html = await response.text();
    console.log('HTML Length:', html.length);
    console.log('Contains result:', html.includes('result__body'));
    console.log('Status:', response.status);
    if (html.length < 2000) {
      console.log('HTML:', html);
    }
  } catch (e) {
    console.error('Fetch Error:', e);
  }
}
test();
