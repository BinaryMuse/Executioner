var multiplier = (process.argv[2] == '--fast') ? 500 : 2000;

var random = Math.random();

var doRandom = function() {
  var newRandom = Math.random();
  if(newRandom > 0.9) {
    console.error(Math.floor(newRandom * 101));
  } else {
    console.log(Math.floor(newRandom * 101));
  }
  setTimeout(doRandom, newRandom * multiplier);
};

setTimeout(function() {
  doRandom()
}, random);

process.on('SIGTERM', function() {
  console.error("Detected SIGTERM. Exiting!");
  process.exit(0);
});

process.on('SIGINT', function() {
  console.error("Detected SIGINT. Exiting!");
  process.exit(0);
});
