function clearConsole() {
    d = document.querySelector("#console-output")
    d.innerText = "";
    d.scrollTop = d.scrollHeight;    
}

eel.expose(clearConsole)

function writeToConsole(text, user_input=false) {
    d = document.querySelector("#console-output")
    if (user_input) d.innerText += "$ ";
    d.innerText += text + "\n";
    d.scrollTop = d.scrollHeight;
}

eel.expose(writeToConsole);

function setSimulationConsole(text) {
  d = document.querySelector("#simulation-output")
  d.innerText = text;
  d.scrollTop = d.scrollHeight;
}

eel.expose(setSimulationConsole);

function setSepoliaConsole(text) {
  d = document.querySelector("#sepolia_infos")
  d.innerText = text;
  d.scrollTop = d.scrollHeight;
}

eel.expose(setSepoliaConsole);

const inputElement = document.querySelector('#console-input');
inputElement.addEventListener('keyup', function(event) {
  if (event.key === 'Enter') {
    let text = inputElement.value
    console.log(text)
    inputElement.value = "";
    writeToConsole(text, true);
    eel.query(text)
  }
});

eel.query("help")

function query(text) {
    writeToConsole(text, true)
    eel.query(text)
}

// -----------------------------------------------------------------
