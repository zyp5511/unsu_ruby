i="-5"
	suffix='torso_cele_dpm';dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt --th2=$i -v --fnwidth 64|tee dpm_cele_all_$i.txt
	suffix='torso_cele_dpm';dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt --th2=$i -v --fnwidth 64|tee dpm_cele_frontal_$i.txt

