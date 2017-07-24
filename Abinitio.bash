#!/bin/bash

#Written by Sari Sabban on 2-July-2017. For communication email me at sari.sabban@gmail.com

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
{ROSETTA}/main/source/bin/relax.default.linuxgccrelease -database {ROSETTA}/main/database -s ./structure.pdb -native ./structure.pdb -relax:thorough -in:file:fullatom -nooutput -nstruct 100 -out:file:silent ./relax.out
grep SCORE ./relax.out | awk '{print $20 "\t" $2}' > ./relax.dat
sed -i '/rms/d' relax.dat
{ROSETTA}/main/source/bin/combine_silent.default.linuxgccrelease -in:file:silent ./fold_silent_*.out -out:file:silent ./fold.out
grep SCORE ./fold.out | awk '{print $28 "\t" $29}' > ./fold.dat
tail -n +2 "./fold.dat" > "./fold.dat.tmp" && mv "./fold.dat.tmp" "./fold.dat"
mkdir ./cluster
grep SCORE ./fold.out | sort -nk +2 | head -200 | awk '{print $31}' > ./list
cat ./list | awk '{print}' ORS=" " > ./liststring
xargs {ROSETTA}/main/source/bin/extract_pdbs.linuxgccrelease -in::file::silent ./fold.out -out:pdb -in:file:tags < ./liststring
rm ./list
rm ./liststring
rm ./*.fsc
rm ./fold_silent_*
rm ./Abinitio.o*
mv *_*.pdb ./cluster
cd ./cluster
{ROSETTA}/main/source/bin/cluster.default.linuxgccrelease -database {ROSETTA}/main/database -in:file:fullatom -cluster:radius 3 -nooutput -out:file:silent ./cluster.out -in:file:s ./*.pdb
rm ./*.pdb
{ROSETTA}/main/source/bin/extract_pdbs.linuxgccrelease -in::file::silent ./cluster.out -out:pdb -in:file:tags
cd ..
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
gnuplot < gnuplot_sets
rm gnuplot_sets
EOF

qsub abinitio.pbs && qsub -W depend=after:${PBS_ARRAY_ID} cluster.pbs
