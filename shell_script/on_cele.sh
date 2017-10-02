work_dir='/home/lichao/research/vault/cele2017'
img_dir='/home/lichao/research/vault/nips/data/test/'
#scan_record='$work_dir/scan_voc2007_test_80k_sampled_8px.txt'
nips_clusters='/home/lichao/git/posecpp/model/nips_clusters.txt'
nips_transforms='/home/lichao/git/posecpp/model/nips_transforms.txt' # torso
nips_head_transforms='/home/lichao/git/posecpp/model/nips_head_transforms.txt'
annot_all=$work_dir'/annot_cele_torso_all.txt'
annot_frontal=$work_dir'/annot_cele_torso_frontal.txt'
head_clusters='/home/lichao/git/posecpp/model/head_clusters_46.txt'
options=''
#options=' --plot'

h3d_img_dir='/home/lichao/scratch/h3d/images/'
annot_h3d='~/scratch/h3d/annot_torso_h3d.txt'

if [ $# -eq 0 ]
then
	echo "No arguments supplied"
else
	if [ -z "$2" ]
	then
		margin=0
	else 
		margin=$2
	fi
	echo "margin set: "$margin

	if [ -z "$3" ]
	then
		step=16
	else 
		step=$3
	fi

	if [ -z "$4" ]
	then
		i=5
	else 
		i=$4
	fi
	scan_record=${work_dir}/scan/scan_cele_${step}pix_knn_11.txt
	case $1 in
		bywords)
			echo "Simple mode: "
			### ours_on_cele.sh

			### use head nodes from previous study as project target
			#ruby ../record_|tee complex_$i\_$j.txt &to_head.rb -s $img_dir -r $scan_record -n $head_clusters -t $nips_transforms -o $work_dir/torso_cele_8pix_head_bywords_1.txt --gfilter bywords --bias --group_threshold 1
			#suffix='torso_cele_8pix_head_bywords_1';dir=all_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot -p $work_dir/$suffix.txt -v   $options

			ruby ../record_to_head.rb -s $img_dir -r $scan_record -n $nips_clusters -t $nips_transforms -o $work_dir/torso_cele_${step}pix_bywords_$i.txt --gfilter bywords --bias --group_threshold $i --margin $margin
			suffix=torso_cele_${step}pix_bywords_$i;dir=all_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot_all -p $work_dir/$suffix.txt -v   $options
			suffix=torso_cele_${step}pix_bywords_$i;dir=frontal_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot_frontal -p $work_dir/$suffix.txt -v   $options
			;;

		complex)
			echo "Complex mode: ours_on_cele_complex.sh"
			### ours_on_cele_complex.sh
			ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms -o $work_dir/torso_cele_${step}pix_complex_$i.txt --gfilter complex --bias --group_threshold $i --margin $margin
			suffix=torso_cele_${step}pix_complex_$i;dir=all_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot_all -p $work_dir/$suffix.txt -v   $options
			suffix=torso_cele_${step}pix_complex_$i;dir=frontal_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot_frontal -p $work_dir/$suffix.txt -v   $options
			;;

		headanchor)
			echo "Head anchored complex mode: ours_on_cele_complex_headanchored.sh"
			### ours_on_cele_complex_head_anchored.sh
			suffix=torso_cele_${step}pix_headanchor_$i
			if [ ! -e $work_dir/$suffix.txt ]
			then
				ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms --anchor-transform $nips_head_transforms -o $work_dir/$suffix.txt --gfilter complex  --bias --group_threshold $i 
			fi
			dir=all_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot_all -p $work_dir/$suffix.txt -v   $options
			dir=frontal_$suffix;rm -r $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir/ -a $annot_frontal -p $work_dir/$suffix.txt -v   $options
			;;

		haha)
			echo "haha"
			;;
		*)
			echo "Wrong argument"
	esac
fi

echo "all done!"
