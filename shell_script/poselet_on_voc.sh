img_dir='/home/lichao/scratch/poselets/data/test/'
annot='/home/lichao/scratch/nips/annot_pascal_2007_test.txt'

for i in {3.6,7.2,14.4,28.8}; do 
	suffix='torso_voc_poselet';dir=$suffix\_$i;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt --th2 $i -v --annotheight 200|tee poselet_voc_$i.txt &
done

