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
#PBS -l walltime=09:00:00
#PBS -l select=1:ncpus=1
#PBS -j oe
#PBS -J 1-42

cd $PBS_O_WORKDIR
module use /app/utils/modules && module load gcc-4.9.2
for i in {1..24}; do
  {ROSETTA}/main/source/bin/AbinitioRelax.default.linuxgccrelease \
    -database {ROSETTA}/main/database \
    -in:file:native ./structure.pdb \
    -in:file:fasta ./structure.fasta \
    -in:file:frag3 ./frags.200.3mers \
    -in:file:frag9 ./frags.200.9mers \
    -psipred_ss2 ./pre.psipred.ss2 \
    -nstruct 25 \
    -abinitio:relax \
    -use_filters true \
    -abinitio::increase_cycles 10 \
    -abinitio::rg_reweight 0.5 \
    -abinitio::rsd_wt_helix 0.5 \
    -abinitio::rsd_wt_loop 0.5 \
    -relax::fast \
    -out:file:silent ./fold_silent_$i-${PBS_ARRAY_INDEX}.out &
done
wait
{ROSETTA}/main/source/bin/relax.default.linuxgccrelease \
    -database {ROSETTA}/main/database \
    -s ./structure.pdb \
    -native ./structure.pdb \
    -relax:thorough \
    -in:file:fullatom \
    -nooutput \
    -nstruct 1 \
    -out:file:silent ./relax_${PBS_ARRAY_INDEX}.out
EOF

cat << 'EOF' > cluster.pbs
#!/bin/bash
#PBS -N Clustering
#PBS -q thin
#PBS -l walltime=03:00:00
#PBS -l select=1:ncpus=24
#PBS -j oe

cd $PBS_O_WORKDIR
{ROSETTA}/main/source/bin/combine_silent.default.linuxgccrelease -in:file:silent ./relax_*.out -out:file:silent ./relax.out
grep SCORE ./relax.out | awk '{print $23 "\t" $24}' > ./relax.dat
sed -i '/rms/d' relax.dat
{ROSETTA}/main/source/bin/combine_silent.default.linuxgccrelease -in:file:silent ./fold_silent_*.out -out:file:silent ./fold.out
grep SCORE ./fold.out | awk '{print $30 "\t" $31}' > ./fold.dat
tail -n +2 "./fold.dat" > "./fold.dat.tmp" && mv "./fold.dat.tmp" "./fold.dat"
mkdir ./cluster
grep SCORE ./fold.out | sort -nk +2 | head -200 | awk '{print $33}' > ./list
cat ./list | awk '{print}' ORS=" " > ./liststring
xargs {ROSETTA}/main/source/bin/extract_pdbs.linuxgccrelease -in::file::silent ./fold.out -out:pdb -in:file:tags < ./liststring
rm ./list
rm ./liststring
rm ./*.fsc
rm ./relax_*
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
plot './fold.dat' lc rgb 'red' pointsize 0.2 pointtype 7 title '', './relax.dat' lc rgb 'green' pointsize 0.2 pointtype 7 title ''
exit" > gnuplot_sets
gnuplot < gnuplot_sets
rm gnuplot_sets
EOF
