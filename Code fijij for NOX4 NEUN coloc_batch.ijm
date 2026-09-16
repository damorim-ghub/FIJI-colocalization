// Fiji Multi-Folder Automation - NEURON ANALYSIS (IMAGE CALCULATOR VERSION)
// =========================================================================
// 1. PATHWAYS & YOUR EXACT VISUAL THRESHOLDS
// =========================================================================
inputParentDir = "Choose the Input Directory containing your images"; 
outputCsvPath  = "Choose the Output Folder"; 

neuronThreshold = 50;  // ch1: 50-255
nox4Threshold   = 58;  // ch3: 58-255

neuronKeyword   = "_ch01_";  // Neurons (Green)
nox4Keyword     = "_ch03_";  // NOX4 (Red)
// =========================================================================

File.makeDirectory("Choose the Output Folder");
if (File.exists(outputCsvPath)) { File.delete(outputCsvPath); }
File.append("Animal_Folder,NOX4_Percent_Area_Inside_Neurons", outputCsvPath);

print("--- Starting Silent NEURON Image Calculator Analysis ---");
setBatchMode(true); 
processFolder(inputParentDir);
setBatchMode(false);
print("--- Neuron Analysis Complete! ---");

function processFolder(currentDir) {
    list = getFileList(currentDir);
    neuronPath = ""; nox4Path = "";
    for (i = 0; i < list.length; i++) {
        if (File.isDirectory(currentDir + list[i])) {
            processFolder(currentDir + list[i]);
        } else {
            fileName = toLowerCase(list[i]);
            if ((endsWith(fileName, ".tif") || endsWith(fileName, ".tiff")) && indexOf(fileName, "overlay") == -1 && indexOf(fileName, "merge") == -1) {
                if (indexOf(fileName, neuronKeyword) != -1) neuronPath = currentDir + list[i];
                if (indexOf(fileName, nox4Keyword) != -1)   nox4Path = currentDir + list[i];
            }
        }
    }
    if (neuronPath != "" && nox4Path != "") {
        parts = split(currentDir, "/"); animalName = parts[parts.length-1];
        print("Processing Neurons: " + animalName);
        
        open(neuronPath); rename("Neurons"); run("8-bit");
        open(nox4Path); rename("NOX4"); run("8-bit");
        
        // Umbralizar canales de forma independiente convirtiéndolos en máscaras binarias limpias
        selectWindow("Neurons"); setThreshold(neuronThreshold, 255); run("Convert to Mask");
        run("Dilate"); run("Close-"); // Unificar procesos celulares
        
        selectWindow("NOX4"); setThreshold(nox4Threshold, 255); run("Convert to Mask");
        
        // Multiplicación física de máscaras: Solo sobreviven los píxeles donde Co-existen ambos
        imageCalculator("AND create", "Neurons", "NOX4");
        rename("Overlap");
        
        // Medir el porcentaje total ocupado estrictamente dentro del molde de la neurona
        run("Clear Results");
        run("Set Measurements...", "area_fraction display redirect=None decimal=3");
        selectWindow("Overlap"); run("Measure");
        
        percentArea = 0;
        if (nResults > 0) { percentArea = getResult("%Area", nResults - 1); }
        
        File.append(animalName + "," + percentArea, outputCsvPath);
        run("Close All");
    }
}
