// Fiji Multi-Folder Automation - ASTROCYTE ANALYSIS (IMAGE CALCULATOR VERSION)
// =========================================================================
// 1. PATHWAYS & YOUR EXACT VISUAL THRESHOLDS
// =========================================================================
inputParentDir = "/Users/danie/Desktop/NEUN GFAP NOX4 max projection/"; 
outputCsvPath  = "/Users/danie/Desktop/FIJI NEUN GFAP NOX4/Astrocyte_GFAP_NOX4_Results.txt";

astroThreshold  = 46;  // ch2: 46-255
nox4Threshold   = 58;  // ch3: 58-255

astroKeyword    = "_ch02_";  // Astrocytes (GFAP)
nox4Keyword     = "_ch03_";  // NOX4 (Red)
// =========================================================================

File.makeDirectory("/Users/danie/Desktop/FIJI NEUN GFAP NOX4/");
if (File.exists(outputCsvPath)) { File.delete(outputCsvPath); }
File.append("Animal_Folder,NOX4_Percent_Area_Inside_Astrocytes", outputCsvPath);

print("--- Starting Silent ASTROCYTE Image Calculator Analysis ---");
setBatchMode(true); 
processFolder(inputParentDir);
setBatchMode(false);
print("--- Astrocyte Analysis Complete! ---");

function processFolder(currentDir) {
    list = getFileList(currentDir);
    astroPath = ""; nox4Path = "";
    for (i = 0; i < list.length; i++) {
        if (File.isDirectory(currentDir + list[i])) {
            processFolder(currentDir + list[i]);
        } else {
            fileName = toLowerCase(list[i]);
            if ((endsWith(fileName, ".tif") || endsWith(fileName, ".tiff")) && indexOf(fileName, "overlay") == -1 && indexOf(fileName, "merge") == -1) {
                if (indexOf(fileName, astroKeyword) != -1)  astroPath = currentDir + list[i];
                if (indexOf(fileName, nox4Keyword) != -1)   nox4Path = currentDir + list[i];
            }
        }
    }
    if (astroPath != "" && nox4Path != "") {
        parts = split(currentDir, "/"); animalName = parts[parts.length-1];
        print("Processing Astrocytes: " + animalName);
        
        open(astroPath); rename("Astrocytes"); run("8-bit");
        open(nox4Path); rename("NOX4"); run("8-bit");
        
        // Umbralizar canales de forma independiente convirtiéndolos en máscaras binarias limpias
        selectWindow("Astrocytes"); setThreshold(astroThreshold, 255); run("Convert to Mask");
        run("Dilate"); run("Close-"); // Unificar ramificaciones astrocitarias
        
        selectWindow("NOX4"); setThreshold(nox4Threshold, 255); run("Convert to Mask");
        
        // Multiplicación física de máscaras: Solo sobreviven los píxeles donde Co-existen ambos
        imageCalculator("AND create", "Astrocytes", "NOX4");
        rename("Overlap");
        
        // Medir el porcentaje total ocupado estrictamente dentro del molde del astrocito
        run("Clear Results");
        run("Set Measurements...", "area_fraction display redirect=None decimal=3");
        selectWindow("Overlap"); run("Measure");
        
        percentArea = 0;
        if (nResults > 0) { percentArea = getResult("%Area", nResults - 1); }
        
        File.append(animalName + "," + percentArea, outputCsvPath);
        run("Close All");
    }
}
