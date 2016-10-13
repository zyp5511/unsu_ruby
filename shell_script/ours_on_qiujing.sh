ruby ../record_to_head.rb -s ~/data/qiujing/images/ -r ~/data/qiujing/scan.txt -n ~/git/posecpp/model/head_clusters_46.txt -t ~/git/posecpp/model/nips_head_transforms.txt -o ~/data/qiujing/head_qj_head_bywords_1.txt --bywords --group_threshold 1
ruby ../simple_process_rect.rb -o draw -s ~/data/qiujing/images/ -d ~/data/qiujing/res_head_qj_head_bywords_1 -r ~/data/qiujing/head_qj_head_bywords_1.txt


ruby ../record_to_head.rb -s ~/data/qiujing/images/ -r ~/data/qiujing/scan.txt -n ~/git/posecpp/model/head_clusters_46.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/data/qiujing/torso_qj_head_bywords_1.txt --bywords --bias --group_threshold 1
ruby ../simple_process_rect.rb -o draw -s ~/data/qiujing/images/ -d ~/data/qiujing/res_torso_qj_head_bywords_1 -r ~/data/qiujing/torso_qj_head_bywords_1.txt 


for((i=1;i<5;i++)) do
	ruby ../record_to_head.rb -s ~/data/qiujing/images/ -r ~/data/qiujing/scan.txt -n ~/git/posecpp/model/nips_clusters.txt -t ~/git/posecpp/model/nips_transforms.txt -o ~/data/qiujing/torso_qj_nips_bywords_$i.txt --bywords  --bias --group_threshold $i  --margin 2
	ruby ../simple_process_rect.rb -o draw -s ~/data/qiujing/images/ -d ~/data/qiujing/res_torso_qj_nips_bywords_$i -r ~/data/qiujing/torso_qj_nips_bywords_$i.txt 
done
