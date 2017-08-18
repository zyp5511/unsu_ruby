#!/bin/bash
if [ $# -eq 0 ]
then
	echo "No arguments supplied"
else
	echo "scanning on "$1" with stride "$2"pix."
	rm -rf /home/lichao/smaller/vault/caltech_sepa/single_face/all_head_cele_${2}pix_bywords_1/$1/
	mkdir -p /home/lichao/smaller/vault/caltech_sepa/single_face/all_head_cele_${2}pix_bywords_1/$1/
	ruby ../process_rect.rb if draw_group_quality /home/lichao/smaller/vault/cele2017/all_head_cele_${2}pix_bywords_1/$1/ /home/lichao/smaller/vault/caltech_sepa/single_face/all_head_cele_${2}pix_bywords_1/$1/ /home/lichao/smaller/vault/cele2017/scan_all_head_cele_${2}pix_bywords_1_$1.txt /home/lichao/smaller/vault/caltech_sepa/single_face/kmeans_800_64.txt nil /home/lichao/smaller/vault/caltech_sepa/single_face/net2_raw.txt /home/lichao/smaller/vault/caltech_sepa/single_face/net2_el.txt /home/lichao/smaller/vault/caltech_sepa/single_face/global_summary.txt /home/lichao/smaller/vault/caltech_sepa/single_face/voro_centers.txt
fi
