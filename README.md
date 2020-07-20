# RosettaAbinitio
A Bash Script For A Completely Automated Rosetta Abinitio Protocol.

## Description:
This is a Bash script that automatically sets the correct files and folders then automatically submitts a calculation job to run Rosetta Abinitio (default for 25,000 decoys) followed by Clustering (lowest 200 scoring decoys) followed by plotting the computation result (Score vs RMSD). This script is to be run on a HPC (High Preformace Computer) that uses PBS as its job scheduler. The script for the SLURM job scheduler is untested.

Written by Sari Sabban on 2-July-2017. For communication email me at sari.sabban@gmail.com

## How To Use:
Here is a [video](https://youtu.be/y6-1UUEf4Pw) that explains the script and how to modify it.
1. Before using this script you must make sure it works in your HPC by running each section individually, job chaining (what this script does) can disrupt the HPC if run incorrectly. There are lines in this script that only works in specific supercomputers and not others, therefore you must optimise this script to your particular HPC.
2. It goes without saying that you need to download and compile the [Rosetta modeling software](https://www.rosettacommons.org) to be able to use this script. Good understanding of how Abinitio works in Rosetta will *GREATLY* help you modify this script to accomodate your HPC and your specific needs.
3. Identify the path to Rosetta and update this script using this command:

`sed -i 's^{ROSETTA}^PATH/TO/ROSETTA^g' Abinitio_pbs.bash`

or

`sed -i 's^{ROSETTA}^PATH/TO/ROSETTA^g' Abinitio_slurm.bash`

4. Make sure you have all the nessesary input files in the working directory.

|   | File Name             | Description                                    |
|---|-----------------------|------------------------------------------------|
| 1 | frags.200.3mers       | The 3-mer fragment file                        |
| 2 | frags.200.9mers       | The 9-mer fragment file                        |
| 3 | structure.pdb         | The structure's PDB file                       |
| 4 | structure.fasta       | The structure's sequence file in FASTA format  |
| 5 | pre.psipred.ss2       | The PsiPred prediction file                    |

5. Execute this script from within the working directory to generate all necessary files and folders using this command:

`bash Abinitio_pbs.bash`

or

`bash Abinitio_slurm.bash`

Then submit the generated files abinitio and cluster files as per your spesific job scheduler command (qsub for PBS and sbatch for SLURM).

6. Make sure your HPC has gnuplot installed to allow for the final result to be generated into a PDF plot. 

7. The default computation settings are for normal Abinitio computation (25,000 decoys). You will have to change the *array* and *-nstruct* values to acheive 1,000,000 decoys that is sometimes required for publications.

8. Running the script will automatically generate the submission files and then automatically submit them.
