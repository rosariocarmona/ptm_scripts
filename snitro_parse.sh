
#! /usr/bin/env bash

######################################################################
#1.- Declaring variables
######################################################################
#Define input files (e.g. SNOSite_output=SNOSite_output1.htm,SNOSite_output2.htm)
iSNOAAPair_output=
GPSSNO_output=
SNOSite_output=
annotation=



####################################
#2.- PARSING iSNO-AAPair output
####################################

echo $iSNOAAPair_output | sed 's/,/\n/g' > list_files

#Extract protein identifier and S-nitrosylation position	

	for i in `cat list_files`; do

		dos2unix $i
		sed 's/protein_seq_/\nprotein_seq_/g' $i > file1
		grep -v 'No Predicted' file1 > file2
		grep 'protein_seq_' file2 > file3
		sed -i 's/<tr align="center"><td><font color="#0000FF" face="Courier">/\n/g' file3
		sed -i 's/<\/font>.*/;/g' file3
		sed 's/<\/td>.*//g' file3| sed 's/^/>/'| sed 's/>protein_seq_//g' > file4
		sed ':a;N;$!ba;s/\n>/\t/g' file4| sed 's/;\t/;/g'| sed 's/.$//g' > parsed_$i.txt

		rm file*

	done

cat parsed*.txt > list_iSNOAAPair_protein_position.txt


#Extract list of putative S-nitrosylated proteins

cut -f 1 list_iSNOAAPair_protein_position.txt > list_iSNOAAPair_protein.txt


rm list_files parsed*

####################################



####################################
#3.- PARSING GPS-SNO output
####################################

echo $GPSSNO_output | sed 's/,/\n/g' > list_files

#Extract protein identifier and S-nitrosylation position	

	for i in `cat list_files`; do

		dos2unix $i
		cut -f 1 $i| sed '1d'| sed ':a;N;$!ba;s/\n>/\t>/g'| sed 's/>.*\t>/>/g' > output
		sed -i 's/\t>/\n>/g' output

			if [[ `tail -n 1 output` == ">"* ]]
				then
					sed -i '$d' output
			fi


			while read line; do
					if [[ $line == [0-9]* ]]
						then
							echo $line";"
						else
							echo $line
					fi
			done < output > file

		sed -i ':a;N;$!ba;s/\n/\t/g' file
		sed -i 's/>protein_seq_/\n/g' file
		sed 's/;\t/;/g' file| sed '1d'| sed 's/.$//g' > parsed_$i.txt

		rm output file

	done

cat parsed*.txt > list_GPSSNO_protein_position.txt


#Extract list of putative S-nitrosylated proteins

cut -f 1 list_GPSSNO_protein_position.txt > list_GPSSNO_protein.txt


rm list_files parsed*

####################################



####################################
#4.- PARSING SNOSite output
####################################

echo $SNOSite_output | sed 's/,/\n/g' > list_files

# Extract protein identifier and S-nitrosylation position

	for i in `cat list_files`; do

		dos2unix $i
		sed ':a;N;$!ba;s/\n//g' $i > output
		sed -i 's/>protein_seq/\n>protein_seq/g' output
		sed -i '1d' output
		sed -i 's/<\/font><\/div><\/b><\/td><td><b><div align="center"><font color="#999999" face="Courier New, Courier, mono" size="2">/\t/g' output
		cut -f 1,2 output| sed 's/>protein_seq_//g' > position
		cut -f 1 position| sort| uniq > id

		# Concentrate S-nitrosylation positions per protein
			for j in `cat id`; do
			 	grep "${j}" position >> file1
			 	cut file1 -f 2| sed ':a;N;$!ba;s/\n/;/g' > file2
			 	echo -e "${j}\t`cat file2`" >> parsed_$i.txt
			 	rm file*
			done

		rm output position id

	done

cat parsed*.txt > list_SNOSite_protein_position.txt


#Extract list of putative S-nitrosylated proteins

cut -f 1 list_SNOSite_protein_position.txt > list_SNOSite_protein.txt


rm list_files parsed*

####################################



####################################
#5.- INTERSECTING lists of proteins
####################################

#Extract list of common proteins to all tools

cat list_iSNOAAPair_protein.txt list_GPSSNO_protein.txt| sort| uniq -d| cat - list_SNOSite_protein.txt| sort| uniq -d > final_common_protein.txt

####################################



####################################
#6.- ADDING ANNOTATION DATA
####################################

#Add annotation data to final list of proteins

if [ "$annotation" ]
	then
		sort -k 1 $annotation > annotation_sort.txt
		join final_common_protein.txt annotation_sort.txt -t $'\t' > final_common_protein_annot.txt
		rm annotation_sort.txt
fi

####################################

