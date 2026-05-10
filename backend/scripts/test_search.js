async function testMojeek() {
  const url = 'https://www.mojeek.com/search?q=' + encodeURIComponent('IPL score today');
  const response = await fetch(url);
  const html = await response.text();
  
  console.log('HTML length:', html.length);
  
  // Mojeek uses h2 with a link for titles
  const titleRegex = /<h2[^>]*>\s*<a[^>]*>([\s\S]*?)<\/a>\s*<\/h2>/gi;
  const snippetRegex = /<p class="s">([\s\S]*?)<\/p>/gi;
  
  const results = [];
  let match;
  while ((match = titleRegex.exec(html)) && results.length < 5) {
    const title = match[1].replace(/<[^>]*>/g, '').trim();
    const sMatch = snippetRegex.exec(html);
    const snippet = sMatch ? sMatch[1].replace(/<[^>]*>/g, '').trim() : '';
    results.push({ title, snippet });
  }
  
  console.log('\nResults found:', results.length);
  results.forEach((r, i) => {
    console.log(`\n[${i+1}] ${r.title}`);
    console.log(`    ${r.snippet}`);
  });
}

testMojeek().catch(e => console.error(e));
