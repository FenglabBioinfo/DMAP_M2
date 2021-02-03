#! /usr/bin/perl
use utf8;
use strict;
use warnings;
use Getopt::Long;
use PerlIO::gzip;
use 5.16.0;

&main;
sub main{
	my %opts = &Help();
	my %hash = &get_uniq(@{$opts{"i"}});
	&print_out(\%hash,$opts{"o"});
}

sub print_out{
	my ($hash,$out_file)=@_;
	if($out_file =~ /.vcf$/){
		$out_file="$out_file.gz";
	}elsif($out_file !~ /.vcf.gz$/){
		$out_file="$out_file.vcf.gz";
	}
	open F,">:gzip",$out_file or die $!;
	say F "##fileformat=VCFv4.2";
	say F "#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tSAMPLE";
	foreach my $chr (sort keys %{$hash}){
		foreach my $pos (sort {$a<=>$b} keys %{$$hash{$chr}}){
			my $ref_alt=$$hash{$chr}{$pos};
			say F "$chr\t$pos\t\.\t$ref_alt\t\.\t\.\tGT\t1\/1";
		}
	}
	close F;
}

sub get_uniq{
	my @input=@_;
	my %hash;
	foreach my $input_file (@input){
		if($input_file=~/gz$/){
			open F,"<:gzip",$input_file or die $!;
		}else{
			open F,$input_file or die $!;
		}
		while(<F>){
			next if(/^#/);
			my @tmp=split "\t";
			my ($chr,$pos,$ref,$alt)=@tmp[0,1,3,4];
			$hash{$chr}{$pos}="$ref\t$alt";
		}
		close F;
	}
	return %hash;
}

sub Help{
	my %opts;
	my $usage = <<"USAGE";
Usage:
	perl $0  --background <vcf1> --background <vcf2> --output <vcf> [options]
	--background	-i	Input VCF files
	--output	-o	Output VCF files
	--help		-h	Help
	--version	-v	Version of the script
Example:
	perl $0 --background ./Example/background.vcf.gz --output ./Example/background.merge.vcf.gz
Note:
	The script is to get the common variations which happened in two or more VCF type files.
Version: 
	Version 1.0, Date: 2020-12-15
Author:
	Zhou Huangkai, hkzhou\@genedenovo.com
	Tang Kuanqiang, tangkuanqiang\@iga.cas.cn

USAGE
	Getopt::Long::GetOptions('help|h'     => \$opts{"h"},
							'version|v'   => \$opts{"v"},
							'background|i=s@'   => \$opts{"i"},
							'output|o=s'  => \$opts{"o"});
	die $usage if($opts{"h"} || $opts{"v"});
	die $usage if(!$opts{"i"} || !$opts{"o"});
	return %opts;
}
