#!/bin/bash

<<COMMENT
Written by Sari Sabban on 2-July-2017. For communication email me at sari.sabban@gmail.com

To generate the files just run the following command:
bash ~/Abinitio.bash
Then submit the abinitio.pbs file first, and once it is done submit the cluster.pbs file.

To run both .pbs files, one after the other, use the following command:
bash ~/Abinitio.bash && qsub abinitio.pbs && qsub -W depend=after:${PBS_ARRAY_ID} cluster.pbs
But this does not always works and can result in errors.
COMMENT
#---------------------------------------------------------------------------------------------------------------
cat << 'EOF' > abinitio.pbs
#!/bin/bash
#PBS -N Abinitio
#PBS -q thin
#PBS -l walltime=9:00:00
#PBS -l select=1:ncpus=1
#PBS -j oe
#PBS -J 1-1000

cd $PBS_O_WORKDIR
{ROSETTA}/main/source/bin/AbinitioRelax.default.linuxgccrelease -database {ROSETTA}/main/database -in:file:frag3 ./aat000_03_05.200_v1_3 -in:file:frag9 ./aat000_09_05.200_v1_3 -in:file:fasta ./structure.fasta -in:file:native ./structure.pdb -psipred_ss2 ./t000_.psipred_ss2 -nstruct 25 -abinitio:relax -use_filters true -abinitio::increase_cycles 10 -abinitio::rg_reweight 0.5 -abinitio::rsd_wt_helix 0.5 -abinitio::rsd_wt_loop 0.5 -relax::fast -out:file:silent ./fold_silent_${PBS_ARRAY_INDEX}.out
EOF

cat << 'EOF' > cluster.pbs
#!/bin/bash
#PBS -N Clustering
#PBS -q thin
#PBS -l walltime=9:00:00
#PBS -l select=1:ncpus=1
#PBS -j oe

cd $PBS_O_WORKDIR
sleep 1
{ROSETTA}/main/source/bin/relax.default.linuxgccrelease -database {ROSETTA}/main/database -s ./structure.pdb -native ./structure.pdb -relax:thorough -in:file:fullatom -nooutput -nstruct 100 -out:file:silent ./relax.out
sleep 1
grep SCORE ./relax.out | awk '{print $20 "\t" $2}' > ./relax.dat
sleep 1
sed -i '/rms/d' relax.dat
sleep 1
{ROSETTA}/main/source/bin/combine_silent.default.linuxgccrelease -in:file:silent ./fold_silent_*.out -out:file:silent ./fold.out
sleep 1
grep SCORE ./fold.out | awk '{print $28 "\t" $29}' > ./fold.dat
sleep 1
tail -n +2 "./fold.dat" > "./fold.dat.tmp" && mv "./fold.dat.tmp" "./fold.dat"
sleep 1
mkdir ./cluster
sleep 1
grep SCORE ./fold.out | sort -nk +2 | head -200 | awk '{print $31}' > ./list
sleep 1
cat ./list | awk '{print}' ORS=" " > ./liststring
sleep 1
xargs {ROSETTA}/main/source/bin/extract_pdbs.linuxgccrelease -in::file::silent ./fold.out -out:pdb -in:file:tags < ./liststring
sleep 1
rm ./list
sleep 1
rm ./liststring
sleep 1
rm ./*.fsc
sleep 1
rm ./fold_silent_*
sleep 1
rm ./Abinitio.o*
sleep 1
mv *_*.pdb ./cluster
sleep 1
cd ./cluster
sleep 1
{ROSETTA}/main/source/bin/cluster.default.linuxgccrelease -database {ROSETTA}/main/database -in:file:fullatom -cluster:radius 3 -nooutput -out:file:silent ./cluster.out -in:file:s ./*.pdb
sleep 1
rm ./*.pdb
sleep 1
{ROSETTA}/main/source/bin/extract_pdbs.linuxgccrelease -in::file::silent ./cluster.out -out:pdb -in:file:tags
sleep 1
cd ..
sleep 1
echo "set terminal postscript
set output './plot.pdf'
set encoding iso_8859_1
set term post eps enh color
set xlabel 'RMSD (\305)'
set ylabel 'Score'
set yrange [:-80]
set xrange [0:20]
set title 'Abinitio Result'
plot './fold.dat' lc rgb 'red' pointsize 0.2 pointtype 7 title '', \
'./relax.dat' lc rgb 'green' pointsize 0.2 pointtype 7 title ''
exit" > gnuplot_sets
sleep 1
gnuplot < gnuplot_sets
sleep 1
rm gnuplot_sets
EOF
qsub abinitio.pbs && qsub -W depend=after:${PBS_ARRAY_ID} cluster.pbs
