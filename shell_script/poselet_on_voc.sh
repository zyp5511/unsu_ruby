for i in {3.6,7.2,14.4}; do 
	suffix='torso_voc_poselet';dir=all_$suffix\_$i;rm -r ~/scratch/nips/$dir;ruby ../new_diff.rb -s ~/scratch/nips/data/JPEGImages/ -o ~/scratch/nips/$dir/ -a ~/scratch/nips/annot_pascal_2007_test.txt -p ~/scratch/nips/$suffix.txt --th2 $i -v --annotheight 200|tee poselet_voc_all_$i.txt
done

