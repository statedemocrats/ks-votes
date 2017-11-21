// https://medium.com/@chekofif/using-es6-s-proxy-for-safe-object-property-access-f42fa4380b2c
const isObject = obj => obj && typeof obj === 'object';
const hasKey = (obj, key) => key in obj;
const Undefined = new Proxy({}, {
    get: function(target, name){
        return Undefined;
    }
  });
const either = (val,fallback) => (val === Undefined? fallback : val);
function safe(obj) {
  return new Proxy(obj, {
    get: function(target, name){
      return hasKey(target, name) ?
        (isObject(target[name]) ? safe(target[name]) : target[name]) : Undefined;
    }
  });
}
