function toggleOracleManagementMenu() {
    const oracleManagementMenu = document.getElementById("oracle-management-menu");
    if (oracleManagementMenu.style.display === "flex") {
        oracleManagementMenu.style.display = "none";
    } else {
        oracleManagementMenu.style.display = "flex";
        query("refresh_replacement_menu")
    }
}

eel.expose(toggleOracleManagementMenu)

document.addEventListener("keydown", function(event) {
    if (event.key === "Escape") {
        const oracleManagementMenu = document.getElementById("oracle-management-menu");
        oracleManagementMenu.style.display = "none";
    }
});


// --------------------------------------------------------------------------------------

function refreshReplacementMenu(admins, oracles, oraclePropositions, failingOracles) {
    // Update admin select elements
    const adminSelectors = [
        document.getElementById('build_proposition_caller'),
        document.getElementById('build_proposition_vote_caller'),
        document.getElementById('build_proposition_vote_proposition')
    ];
    
    adminSelectors.forEach(selector => {
        // Clear existing options
        while (selector.options.length > 1) {
            selector.remove(1);
        }
        
        // Add new options
        admins.forEach(admin => {
            const option = document.createElement('option');
            option.value = admin;
            option.textContent = admin;
            selector.appendChild(option);
        });
    });
    
    // Update oracle select element
    const oracleSelector = document.getElementById('build_proposition_old_oracle');
    while (oracleSelector.options.length > 1) {
        oracleSelector.remove(1);
    }
    
    oracles.forEach(oracle => {
        const option = document.createElement('option');
        option.value = oracle;
        option.textContent = oracle;
        oracleSelector.appendChild(option);
    });
    
    // Update oracle propositions and failing oracles text
    document.getElementById('oracle_propositions').textContent = oraclePropositions;
    document.getElementById('failing_oracles').textContent = failingOracles;
}

eel.expose(refreshReplacementMenu)