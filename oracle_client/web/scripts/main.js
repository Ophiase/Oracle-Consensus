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
