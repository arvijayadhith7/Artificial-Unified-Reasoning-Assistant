async function test() {
  const url = 'https://html.duckduckgo.com/html/?q=today+ipl+match';
  const response = await fetch(url, { headers: { 'User-Agent': 'Mozilla/5.0' } });
  const html = await response.text();
  console.log(html.substring(2000, 3000));
}
test();
