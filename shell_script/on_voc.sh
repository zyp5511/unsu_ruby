img_dir='/home/lichao/scratch/poselets/data/test/'
#scan_record='/home/lichao/scratch/nips/scan_voc_8pix.txt'
scan_record='/home/lichao/scratch/nips/scan_voc2007_test_80k_sampled_8px.txt'
nips_clusters='/home/lichao/git/posecpp/model/nips_clusters.txt'
nips_transforms='/home/lichao/git/posecpp/model/nips_transforms.txt'
annot='/home/lichao/scratch/nips/annot_pascal_2007_test.txt'
head_clusters='/home/lichao/git/posecpp/model/head_clusters_46.txt'

if [ $# -eq 0 ]
then
	echo "No arguments supplied"
else
	case $1 in
		bywords)
			echo "Simple mode: ours_on_voc.sh"
			### ours_on_voc.sh

			### use head nodes from previous study as project target
			#ruby ../record_|tee complex_$i\_$j.txt &to_head.rb -s $img_dir -r $scan_record -n $head_clusters -t $nips_transforms -o /home/lichao/scratch/nips/torso_voc_8pix_head_bywords_1.txt --gfilter bywords --bias --group_threshold 1
			#suffix='torso_voc_8pix_head_bywords_1';dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200

			for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $scan_record -n $nips_clusters -t $nips_transforms -o /home/lichao/scratch/nips/torso_voc_8pix_bywords_$i.txt --gfilter bywords --bias --group_threshold $i --margin 2
				suffix='torso_voc_8pix_bywords_'$i;dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200|tee bywords_$i\_$j.txt &
			done
			;;

		complex)
			echo "Complex mode: ours_on_voc_complex.sh"
			### ours_on_voc_complex.sh
			if [ -z "$2" ]
			then
				i=2
			else 
				i=$2
			fi
			for((j=0;j<4;j++)) do
				##for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms  -o /home/lichao/scratch/nips/torso_voc2007_8pix_complex_$i\_$j.txt --gfilter complex  --bias --group_threshold $i --margin $j
				suffix='torso_voc2007_8pix_complex_'$i'_'$j;dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200|tee complex_$i\_$j.txt &
				##done
			done
			;;

		complex_group)
			echo "Complex mode: ours_on_voc_complex.sh"
			### ours_on_voc_complex.sh
			if [ $# -lt 2 ]
			then
				j=0
			else 
				j=$2
			fi
			for((i=1;i<5;i++)) do
				##for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms  -o /home/lichao/scratch/nips/torso_voc2007_8pix_complex_$i\_$j.txt --gfilter complex  --bias --group_threshold $i --margin $j
				suffix='torso_voc2007_8pix_complex_'$i'_'$j;dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200
				##done
			done
			;;

		headanchor)
			echo "Head anchored complex mode: ours_on_voc_complex_headanchored.sh"
			### ours_on_voc_complex_head_anchored.sh
			for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms --anchor-transform /home/lichao/git/posecpp/model/nips_head_transforms.txt -o /home/lichao/scratch/nips/torso_voc2007_8pix_headanchor_$i.txt --gfilter complex  --bias --group_threshold $i 
				suffix='torso_voc2007_8pix_headanchor_'$i;dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200
			done
			;;

		haha)
			echo "haha"
			;;
		*)
			echo "Wrong argument"
	esac
fi

echo "all done!"
