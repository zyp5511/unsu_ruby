ruby ../record_to_head.rb -s ~/scratch/nips/data/test/ -r ~/scratch/nips/scan_cele_8pix.txt -n ~/git/posecpp/model/head_clusters_46.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/scratch/nips/torso_cele_8pix_head_bywords_1.txt --bywords --bias --group_threshold 1
suffix='torso_cele_8pix_head_bywords_1';dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt -v --fnwidth 64
suffix='torso_cele_8pix_head_bywords_1';dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt -v --fnwidth 64

for((i=1;i<5;i++)) do
	ruby ../record_to_head.rb -s ~/scratch/nips/data/test/ -r ~/scratch/nips/scan_cele_8pix.txt -n ~/git/posecpp/model/nips_clusters.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/scratch/nips/torso_cele_8pix_nips_bywords_$i.txt --bywords --bias --group_threshold $i 
	suffix='torso_cele_8pix_nips_bywords_'$i;dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt -v --fnwidth 64
	suffix='torso_cele_8pix_nips_bywords_'$i;dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt -v --fnwidth 64
done


#suffix='torso_cele_poselet';dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt --th2 3.6 -v --fnwidth 64
#suffix='torso_cele_poselet';dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt --th2 3.6 -v --fnwidth 64

