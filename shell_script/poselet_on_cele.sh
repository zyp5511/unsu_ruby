for i in {3.6,7.2,14.4}; do 
	suffix='torso_cele_poselet';dir=all_$suffix\_$i;rm -r ~/scratch/nips/$dir;ruby new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt --th2 $i -v |tee poselet_cele_all_$i.txt
	suffix='torso_cele_poselet';dir=cele_$suffix\_$i;rm -r ~/scratch/nips/$dir;ruby new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt --th2 $i -v |tee poselet_cele_frontal_$i.txt
done

