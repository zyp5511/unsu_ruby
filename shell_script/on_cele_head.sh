work_dir='/home/lichao/smaller/vault/cele2017'
img_dir='/home/lichao/smaller/vault/nips/data/test/'
#nips_clusters='/home/lichao/git/posecpp/model/nips_clusters.txt'
#nips_transforms='/home/lichao/git/posecpp/model/nips_transforms.txt'
annot_all='/home/lichao/smaller/vault/nips/old/annot_all.txt'
annot_cele='/home/lichao/smaller/vault/nips/old/annot_cele.txt'
head_clusters='/home/lichao/git/posecpp/model/head_clusters_46.txt'
head_transforms='/home/lichao/git/posecpp/model/head_transforms_46.txt'

if [ $# -eq 0 ]
then
	echo "No arguments supplied"
else
	case $1 in
		byrects)
			echo "Simple mode: (Just rect counting)"
			if [ -z "$2" ]
			then
				margin=0
			else 
				margin=$2
			fi

			if [ -z "$3" ]
			then
				step=16
			else 
				step=$3
			fi
			echo "margin set: "$margin
			for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $work_dir/scan_cele_${step}pix.txt -n $head_clusters -t $head_transforms -o $work_dir/head_cele_${step}pix_byrects_$i.txt --gfilter byrects --group_threshold $i --margin $margin 
				suffix=head_cele_${step}pix_byrects_$i;dir=all_$suffix;rm -rf $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir -a $annot_all -p $work_dir/$suffix.txt -v |tee $dir\_margin_$margin.txt 
				suffix=head_cele_${step}pix_byrects_$i;dir=cele_$suffix;rm -rf $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir -a $annot_cele -p $work_dir/$suffix.txt -v |tee $dir\_margin_$margin.txt 
			done
			;;

		bywords)
			echo "Simple mode: count viewlets"

			if [ -z "$2" ]
			then
				margin=2
			else 
				margin=$2
			fi
			if [ -z "$3" ]
			then
				step=16
			else 
				step=$3
			fi
			echo "margin set: "$margin
			for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $work_dir/scan_cele_${step}pix.txt -n $head_clusters -t $head_transforms -o $work_dir/head_cele_${step}pix_bywords_$i.txt --gfilter bywords --group_threshold $i --margin $margin 
				suffix=head_cele_${step}pix_bywords_$i;dir=all_$suffix;rm -rf $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir -a $annot_all -p $work_dir/$suffix.txt -v |tee $dir\_margin_$margin.txt 
				suffix=head_cele_${step}pix_bywords_$i;dir=cele_$suffix;rm -rf $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir -a $annot_cele -p $work_dir/$suffix.txt -v |tee $dir\_margin_$margin.txt 
			done
			;;

		complex)
			echo "Complex mode: ours_on_cele_complex.sh"
			### ours_on_cele_complex.sh
			if [ -z "$2" ]
			then
				margin=2
			else 
				margin=$2
			fi
			if [ -z "$3" ]
			then
				step=16
			else 
				step=$3
			fi

			if [ -n "$2" ]
			then
				i=$2
			else 
				i=2
			fi

			echo "margin set: "$margin
			for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $work_dir/scan_cele_${step}pix.txt -n $head_clusters -t $head_transforms -o $work_dir/head_cele_${step}pix_bywords_$i.txt --gfilter complex --group_threshold $i --margin $margin 
				suffix=head_cele_${step}pix_bywords_$i;dir=all_$suffix;rm -rf $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir -a $annot_all -p $work_dir/$suffix.txt -v |tee $dir\_margin_$margin.txt 
				suffix=head_cele_${step}pix_bywords_$i;dir=cele_$suffix;rm -rf $work_dir/$dir;ruby ../new_diff.rb -s $img_dir -o $work_dir/$dir -a $annot_cele -p $work_dir/$suffix.txt -v |tee $dir\_margin_$margin.txt 
			done

			for((j=0;j<4;j++)) do
				##for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms  -o /home/lichao/scratch/nips/torso_cele_8pix_complex_$i\_$j.txt --gfilter complex  --bias --group_threshold $i --margin $j
				suffix='torso_cele_8pix_complex_'$i'_'$j;dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200|tee complex_$i\_$j.txt 
				##done
			done
			;;

		complex_group)
			echo "Complex mode: ours_on_cele_complex.sh"
			### ours_on_cele_complex.sh
			if [ $# -lt 2 ]
			then
				j=0
			else 
				j=$2
			fi
			for((i=1;i<5;i++)) do
				##for((i=1;i<5;i++)) do
				ruby ../record_to_head.rb -s $img_dir -r $scan_record --corenode $head_clusters -n $nips_clusters -t $nips_transforms  -o /home/lichao/scratch/nips/torso_cele_8pix_complex_$i\_$j.txt --gfilter complex  --bias --group_threshold $i --margin $j
				suffix='torso_cele_8pix_complex_'$i'_'$j;dir=all_$suffix;rm -r /home/lichao/scratch/nips/$dir;ruby ../new_diff.rb -s $img_dir -o /home/lichao/scratch/nips/$dir/ -a $annot -p /home/lichao/scratch/nips/$suffix.txt -v   --annotheight 200
				##done
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


