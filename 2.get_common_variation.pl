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
		chomp(my ($M,$W)=split);
		$sample_conf{$M}=$W;
		$sample_conf{$W}=$M;
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
			say F2 $line if(length($ref)>1 || length($alt)>1 || ($ref =~ /,/) || ($alt =~ /,/));
			my @count = ($line =~ /1\/1|0\/1/g);
			if(($#count+1)>=3){
				say F2 $line;
			}elsif(($#count+1)==2){
				my @S2;
				for(my $i=0;$i<@tmp;$i++){
					push @S2,$sample[$i] if($tmp[$i] =~ /1\/1|0\/1/);
				}
				say F2 $line if($sample_conf{$S2[0]} ne $S2[1]);
			}
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
			if(length($ref)>1 || length($alt)>1 || ($ref =~ /,/) || ($alt =~ /,/)){
				say F2 $line;
				next;
			}
			my @count = ($line =~ /1\/1|0\/1/g);
			say F2 $line if(($#count+1)>1);
		}
	}
	close F1; close F2;
}

sub Help{
	my %opts;
	my $usage = <<"USAGE";
Usage:
	perl $0 -i <vcf> -o <genome.fai> [options]
	--input  -i	The input file of VCF type, including the variation in two or more M2 populations.
	--output -o	The out file of VCF type, including the common variation.
	--conf   -c	The two samples on the row represent the mutant bulk and wild type bulk from a same M2 population.
Exmple:
	perl $0 --input ./Example/input.vcf.gz --output ./Example/common_variation.vcf.gz
	perl $0 --input ./Example/input.vcf.gz --output ./Example/common_variation.vcf.gz --conf ./Example/sample.conf
Version: 
	Version 1.0, Date: 2020-12-02
Author:
	Zhou Huangkai, hkzhou\@genedenovo.com
	Tang Kuanqiang, tangkuanqiang\@iga.cas.cn

USAGE
	Getopt::Long::GetOptions('help|h'    => \$opts{"h"},
							'version|v'  => \$opts{"v"},
							'input|i=s'  => \$opts{"i"},
							'output|o:s' => \$opts{"o"},
							'conf|c:s' => \$opts{"c"});
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

