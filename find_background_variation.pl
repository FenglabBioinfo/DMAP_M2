#! /usr/bin/perl
use utf8;
use strict;
use warnings;
use PerlIO::gzip;
use File::Basename;
use Getopt::Long;
use Cwd 'abs_path';
use 5.16.0;

&main();
sub main{
	my %opts = &Help();
	if($opts{"c"}){
		&filter1(\%opts);
	}else{
		&filter2(\%opts);
	}
}
sub filter1{
	my %opts=%{$_[0]};
	my ($vcf_in,$vcf_out,$conf)=($opts{i},$opts{o},$opts{c});
	open F3,$conf or die $!;
	my %sample_conf;
	while(<F3>){
		next if(/^#/);
		chomp(my ($family,$sample_name)=split);
		$sample_conf{$sample_name}=$family;
	}
	close F3;
	if($vcf_in =~ /gz$/){
		open F1,"gzip -dc $vcf_in|" or die $!;
	}else{
		open F1,$vcf_in or die $!;
	}
	open F2,">:gzip",$vcf_out or die $!;
	my @sample;
	while(<F1>){
		chomp(my $line=$_);
		if($line =~ /^##/){
			say F2 $line;
		}elsif($line =~ /^#CHROM/){
			say F2 $line;
			my @tmp=split /\t/,$line;
			@sample = @tmp[9...$#tmp];
		}else{
			my ($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@tmp)= split /\t/,$line;
			#say F2 $line if(length($ref)>1 || length($alt)>1 || ($ref =~ /,/) || ($alt =~ /,/));
			my @count = ($line =~ /1\/1|0\/1/g);
			my %S1;
			for(my $i=0;$i<@tmp;$i++){
				$S1{$sample_conf{$sample[$i]}}++ if($tmp[$i] =~ /1\/1|0\/1/);
			}
			my $S1_length=keys %S1;
			say F2 $line if($S1_length>1);
		}
	}
	close F1; close F2;
}

sub filter2{
	my %opts=%{$_[0]};
	my ($vcf_in,$vcf_out)=($opts{i},$opts{o});
	if($vcf_in =~ /gz$/){
		open F1,"gzip -dc $vcf_in|" or die $!;
	}else{
		open F1,$vcf_in or die $!;
	}
	open F2,">:gzip",$vcf_out or die $!;
	while(<F1>){
		chomp(my $line=$_);
		if($line =~ /^#/){
			say F2 $line;
		}else{
			my ($chr,$pos,$id,$ref,$alt,$qual,$filter,$info,$format,@sample)= split /\t/,$line;
			my @count = ($line =~ /1\/1|0\/1/g);
			say F2 $line if($#count>=1);
		}
	}
	close F1; close F2;
}

sub Help{
	my %opts;
	my $usage = <<"USAGE";
Usage:
	perl $0 -i <vcf> -o <vcf> [options]
	--population_genotype  -i	The input file of VCF type contains the variation of all samples.
	--output -o	The out file of VCF type, including the common variation.
	--population_kinship   -c	The file contain 2 column 
                The first column show the family or segragation population of the sample,
                and the second column show the sample name.
Exmple:
	perl $0 --population_genotype ./Example/background.vcf.gz --output ./Example/common_background_variation.vcf.gz
	perl $0 --population_genotype ./Example/background.vcf.gz --output ./Example/common_background_variation.vcf.gz --population_kinship ./Example/sample.conf
Note:
	The script can obtain the variation which happened at least in two samples or at least in two segeragation population if the sample configure file existed. The sample configure file was optional.
Version: 
	Version 1.0, Date: 2020-12-15
Author:
	Zhou Huangkai, hkzhou\@genedenovo.com
	Tang Kuanqiang, tangkuanqiang\@iga.cas.cn

USAGE
	Getopt::Long::GetOptions('help|h'    => \$opts{"h"},
							'version|v'  => \$opts{"v"},
							'population_genotype|i=s'  => \$opts{"i"},
							'output|o:s' => \$opts{"o"},
							'population_kinship|c:s' => \$opts{"c"});
	die $usage if($opts{"h"} || $opts{"v"});
	die $usage if(!$opts{"i"});
	$opts{"i"} = abs_path($opts{"i"});
	die "$opts{i} doesn't exist!" if(! -e $opts{"i"});
	if($opts{"o"}){
		$opts{"o"} = join("",($opts{"o"},"_filter.vcf.gz")) if($opts{"o"} !~ /gz$/);
		my $out_dir=dirname($opts{"o"});
		mkdir $opts{"o"} unless (-e $out_dir);
	}else{
		$opts{"o"} = join("",($opts{"i"},"_filter.vcf.gz"));
	}
	if($opts{"c"}){
		if(-e $opts{"c"}){
			$opts{"c"}=abs_path($opts{"c"});
		}else{
			die "$opts{c} doesn't exist!";
		}
	}
	return %opts;
}

