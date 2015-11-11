for((i=1;i<5;i++)) do
	ruby ../record_to_head.rb -s ~/scratch/h3d/images/ -r ~/scratch/h3d/scan_h3d_cele_8pix.txt --corenode ~/git/posecpp/model/head_clusters_46.txt -n ~/git/posecpp/model/nips_clusters.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/scratch/nips/torso_h3d_8pix_nips_complex_$i.txt --complex  --bias --group_threshold $i  --margin 2 
	suffix='torso_h3d_8pix_nips_complex_'$i;dir=all_$suffix;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/h3d/images/ -o ~/scratch/nips/$dir/ -a ~/scratch/h3d/annot_torso_h3d.txt -p ~/scratch/nips/$suffix.txt -v --annotheight 200|tee $dir.txt &
done



