// https://stackoverflow.com/questions/8486099/how-do-i-parse-a-url-query-parameters-in-javascript
function getJsonFromUrl(hashBased) {
  let query;
  if(hashBased) {
    let pos = location.href.indexOf("#");
    if(pos==-1) return {};
    query = location.href.substr(pos+1);
  } else {
    query = location.search.substr(1);
  }
  let result = {};
  query.split("&").forEach(function(part) {
    if(!part) return;
      part = part.split("+").join(" "); // replace every + with space, regexp-free version
      let eq = part.indexOf("=");
      let key = eq>-1 ? part.substr(0,eq) : part;
      let val = eq>-1 ? decodeURIComponent(part.substr(eq+1)) : "";
      let from = key.indexOf("[");
      if(from==-1) result[decodeURIComponent(key)] = val;
    else {
      let to = key.indexOf("]",from);
      let index = decodeURIComponent(key.substring(from+1,to));
      key = decodeURIComponent(key.substring(0,from));
      if(!result[key]) result[key] = [];
      if(!index) result[key].push(val);
      else result[key][index] = val;
    }
  });
  return result;
}
