ruby ../record_to_head.rb -s ~/scratch/nips/data/test/ -r ~/scratch/nips/scan_cele_8pix.txt --corenode ~/git/posecpp/model/head_clusters_46.txt -n ~/git/posecpp/model/head_clusters_46.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/scratch/nips/torso_cele_8pix_head_complex_1.txt --complex --bias --group_threshold 2 # modified from 1, because of the complex logic
suffix='torso_cele_8pix_head_complex_1';dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt -v |tee $dir.txt &
suffix='torso_cele_8pix_head_complex_1';dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt -v |tee $dir.txt &

for((i=1;i<5;i++)) do
	ruby ../record_to_head.rb -s ~/scratch/nips/data/test/ -r ~/scratch/nips/scan_cele_8pix.txt --corenode ~/git/posecpp/model/head_clusters_46.txt -n ~/git/posecpp/model/nips_clusters.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/scratch/nips/torso_cele_8pix_nips_complex_$i.txt --complex --bias --group_threshold $i --margin 2
	suffix='torso_cele_8pix_nips_complex_'$i;dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_all.txt -p ~/scratch/nips/$suffix.txt -v |tee $dir.txt &
	suffix='torso_cele_8pix_nips_complex_'$i;dir=cele_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/test/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_cele_torso_frontal.txt -p ~/scratch/nips/$suffix.txt -v|tee $dir.txt &
done

