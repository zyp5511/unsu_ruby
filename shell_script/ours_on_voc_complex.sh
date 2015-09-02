for((i=1;i<5;i++)) do
	ruby ../record_to_head.rb -s ~/scratch/nips/data/JPEGImages/ -r ~/scratch/nips/scan_voc_8pix.txt --corenode ~/git/posecpp/model/head_clusters_46.txt -n ~/git/posecpp/model/nips_clusters.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/scratch/nips/torso_voc_8pix_nips_complex_$i.txt --complex  --bias --group_threshold $i 
	suffix='torso_voc_8pix_nips_complex_'$i;dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/JPEGImages/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_pascal_2007_test.txt -p ~/scratch/nips/$suffix.txt -v   --annotheight 200
done


#suffix='torso_cele_poselet';dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/JPEGImages/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt --th2 3.6 -v --fnwidth 64
#suffix='torso_cele_poselet';dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/JPEGImages/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt --th2 3.6 -v --fnwidth 64

