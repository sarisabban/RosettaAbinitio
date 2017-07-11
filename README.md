# RosettaAbinitio
A Bash Script For A Completely Automated Rosetta Abinitio Protocol.

## Description:
This is a Bash script that automatically sets the correct files and folders then automatically submitts a calculation job to run Rosetta Abinitio (default for 25,000 decoys) followed by Clustering (lowest 200 scoring decoys) followed by plotting the computation result (Score vs RMSD). This script is to be run on a HPC (High Preformace Computer) that uses PBS as its job scheduler.

Written by Sari Sabban on 2-July-2017. For communication email me at sari.sabban@gmail.com

## How To Use:
1. Before using this script you must make sure it works in your HPC by running each section individually, job chaining (what this script does) can disrupt the HPC if run incorrectly. There are lines in this script that only works in specific supercomputers and not others, therefore you must optimise this script to your particular HPC.
2. It goes without saying that you need to download and compile the [Rosetta modeling software](https://www.rosettacommons.org) to be able to use this script. Good understanding of how Abinitio works in Rosetta will *GREATLY* help you modify this script to accomodate your HPC and your specific needs.
3. Identify the path to Rosetta and update this script using this command:

`sed -i 's^{ROSETTA}^PATH/TO/ROSETTA^g' Abinitio.bash`

4. Make sure you have all the nessesary input files in the working directory.

|   | File Name             | Description                                    |
|---|-----------------------|------------------------------------------------|
| 1 | aat000_03_05.200_v1_3 | The 3-mer fragment file                        |
| 2 | aat000_09_05.200_v1_3 | The 9-mer fragment file                        |
| 3 | structure.pdb         | The structure's PDB file                       |
| 4 | structure.fasta       | The structure's sequence file in FASTA format  |
| 5 | t000_.psipred_ss2     | The PsiPred prediction file                    |

5. Execute this script from within the working directory to generate all nessesary files and folders using this command:

`bash Abinitio.bash`

6. Make sure your HPC has gnuplot installed to allow for the final result to be generated into a PDF plot. 
7. This script is setup to run using the PBS job scheduler, simple changes can be made to make it work on other job schedulers, but thorough understading of each job scheduler is nessesary to make these modifications.

8. The default computation settings are for normal Abinitio computation (25,000 decoys). You will have to run the following command to change the script to allow it to run a larger computation (1,000,000 decoys):

`sed -i '/#PBS -l walltime=9:00:00/d' Abinitio.bash && sed -i 's/thin/thin_1m/g' Abinitio.bash && sed -i 's/-nstruct 25/-nstruct 1000/g' Abinitio.bash`

9. Here is a [video](youtube.com/) that explains the script and how to modify it. If I did not make a video yet, bug me until I make one.

10. Running the script will automatically generate the submission files and then automatically submit them.
