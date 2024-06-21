// tiny hackernews scrapper

const divs = document.querySelectorAll('div.commtext.c00');
const contentArray = [];
divs.forEach(div => {
  const content = div.textContent.trim();
  contentArray.push(content);
});
return contentArray;