#!/usr/bin/perl


# Bonobo 
# Bond automated research
# terry.leung@genovape.com
#
# version 1.0 - features to download and generate company / bonds data into a CSV file 
# 

use strict;
use warnings;

my $todo = shift || 'noarg';
my $input = shift || 'input.csv';
my $output = shift || 'output.csv';
my $usage = "Usage: bonobo.pl -d|-c|-b input.csv output.csv\n";

if (($todo ne '-d') && ($todo ne '-c') && ($todo ne '-b')) {
	print $usage;
	exit;
} elsif ($todo eq '-d') {
	
	# LOGIC TO DOWNLOAD RELEVANT DATA FROM WEB
	open (MYFILE, $input); 
	while (<MYFILE>) {
	  chomp;
	  my $symbol = $_;
	  $symbol =~ s/\r$//;
	
	  my $url = "http://quicktake.morningstar.com/StockNet/bonds.aspx?Symbol=$symbol&Country=USA";
	  print "$url\n";
	
	  system ("mkdir -p bonobo_db/$symbol");
	  system ("wget -E -H -K -k -p -P ./bonobo_db/$symbol '$url'");
	  system ("cp bonobo_db/$symbol/bond.morningstar.com/internal/*html ./bonobo_db/$symbol/$symbol.html");
	  system ("rm bonobo_db/$symbol/quicktake.morningstar.com/robots.txt");
	}
	close (MYFILE);
	exit;
} elsif ($todo eq "-c") {
	open (CSVOUT, "> $output"); 
	print CSVOUT "Symbol" . "," . "Count" . "," . "MS Rating" . "," . "Amount Outstanding" . "," . "Debt/Asset" . "," . "Sector". "," . "DA" . "," . "DA(I)" . "," . "DE" . "," . "DE(I)" . "," . "Cur/Ratio" . "," . "Cur/Ratio (I)" . "," . "EBIT/Int" . "," . "EBIT/I(I)" . "," . "D/EBIT" . "," . "D/EBIT(I)" . "," . "CF/D" . "," . "CF/D(I)" . "\n";
	close (CSVOUT); 	
} elsif ($todo eq "-b") {
	open (CSVOUT, "> $output"); 
	print CSVOUT "Symbol" . "," . "Sector" . "," . "G-SCORE" . "," ."Maturity" . "," . "Amount(M)" . "," . "Rating" . "," . "Price" . "," . "Coupon". "," . "Coupon Type" . "," . "Callable" . "," . "Rule" . "," . "YTM" . "\n";
	close (CSVOUT); 	
}

# LOGIC TO PARSE COMPANY / BOND DATA
open (MYFILE, $input) or die "'$! $input'\n";; 
while (<MYFILE>) {
    chomp;
    my $symbol = $_;
    $symbol =~ s/\r$//;

    print "Parsing $symbol\n";

	# State-wise variables
	my $big_marker = 0;
	my $small_marker = 0;
	my $state = 0;
	
	# Company Information variables
	my $ms_rating = "";
	my $amt_outstanding = "";
	my $debtasset = "";
	my $comp_sector = "";
	
	my $r_da_c = "";
	my $r_da_i = "";
	my $r_de_c = "";
	my $r_de_i = "";
	my $r_cacl_c = "";
	my $r_cacl_i = "";
	my $r_ebiti_c = "";
	my $r_ebiti_i = "";
	my $r_debit_c = "";
	my $r_debit_i = "";
	my $r_cfd_c = "";
	my $r_cfd_i = "";
	
	my $b_count = 0;
	my $b_maturity = "";
	my $b_amount = "";
	my $b_rating = "";
	my $b_price = "";
	my $b_coupon = "";
	my $b_coupontype = "";
	my $b_callable = "";
	my $b_rule = "";
	my $b_ytm = "";

	if (open (MYCOMP, "< ./bonobo_db/$symbol/$symbol.html")) { 
	while (<MYCOMP>) {
		chomp;
		my $line = $_;
		$line =~ s/\r$//;
		$line =~ s/^\s+//;		# remove leading spaces
		$line =~ s/<\/td>$//;  	# remove trailing tags

		if ($state == 1) {
	
			# Company Summary Analysis
			if ($big_marker == 1) { 
				if ($small_marker == 1) {
					$ms_rating = $line;
				} elsif ($small_marker == 3) {
					$amt_outstanding = $line;
				} elsif ($small_marker == 9) {
					$debtasset = $line;
				} elsif ($small_marker == 11) {
					$comp_sector = $line;
					$state = 0;
				}
	
			## Key Ratio Analysis
			} elsif (($big_marker > 1000) && ($big_marker < 2000)) {
				if ($small_marker == 3) {
					$r_da_c = $line;
				} elsif ($small_marker == 5) {
					$r_da_i = $line;
					$state = 0;
				}
			} elsif (($big_marker > 2000) && ($big_marker < 3000)) {
				if ($small_marker == 3) {
					$r_de_c = $line;
				} elsif ($small_marker == 5) {
					$r_de_i = $line;
					$state = 0;
				}
			} elsif (($big_marker > 3000) && ($big_marker < 4000)) {
				if ($small_marker == 3) {
					$r_cacl_c = $line;
				} elsif ($small_marker == 5) {
					$r_cacl_i = $line;
					$state = 0;
				}
			} elsif (($big_marker > 4000) && ($big_marker < 5000)) {
				if ($small_marker == 3) {
					$r_ebiti_c = $line;
				} elsif ($small_marker == 5) {
					$r_ebiti_i = $line;
					$state = 0;
				}
			} elsif (($big_marker > 5000) && ($big_marker < 6000)) {
				if ($small_marker == 3) {
					$r_debit_c = $line;
				} elsif ($small_marker == 5) {
					$r_debit_i = $line;
					$state = 0;
				}
			} elsif (($big_marker > 6000) && ($big_marker < 7000)) {
				if ($small_marker == 3) {
					$r_cfd_c = $line;
				} elsif ($small_marker == 5) {
					$r_cfd_i = $line;
					$state = 0;
				}
	
			## Bonds Summary Analysis
			} else {
				$line =~ s/<.+?>//g;
				$line =~ s/,//g;
				$line =~ s/---/-/g;
				if ($small_marker == 0) {
					#$b_maturity = $line;
					$b_maturity = substr ($line, 3 ,2) . "/" . substr ($line, 0, 2) . "/" . substr ($line, 6);
				} elsif ($small_marker == 1) {
					$b_amount = $line;
				} elsif ($small_marker == 2) {
					$b_rating = $line;
				} elsif ($small_marker == 3) {
					$b_price = $line;
				} elsif ($small_marker == 4) {
					$b_coupon = $line;
				} elsif ($small_marker == 5) {
					$b_coupontype = $line;
				} elsif ($small_marker == 6) {
					$b_callable = $line;
				} elsif ($small_marker == 7) {
					$b_rule = $line;
				} elsif ($small_marker == 8) {
					$b_ytm = $line;
					$b_count++;
					$state = 0;
					
					if (($todo eq "-b") && ($b_price ne "-")) {
						open (CSVOUT, ">> $output"); 
						print CSVOUT "$symbol" . "," . "$comp_sector" . ",," . "$b_maturity" . "," . "$b_amount" . "," . "$b_rating" . "," . "$b_price" . "," . "$b_coupon". "," . "$b_coupontype" . "," . "$b_callable" . "," . "$b_rule" . "," . "$b_ytm" . "\n";
						close (CSVOUT); 				
					}
				}
			}      
			$small_marker += 1;
	
		} elsif (($line =~ /tr class="text3"/) || ($line =~ /a rel="external" href="http/)) {
			$state = 1;
			$big_marker += 1;
			$small_marker = 0;
		} elsif ($line =~ /tr class="industry_bar/) {
			$state = 1;
			$big_marker += 1000;
			$small_marker = 0;
		} #else ignore
	}
    close (MYCOMP);
    } else {
    	print "'$! ./bonobo_db/$symbol/$symbol.html'\n";
    }
    
    if ($todo eq "-c") {
		open (CSVOUT, ">> $output"); 
		if ($b_count == 0) {
			#No bond data is available
			print CSVOUT "$symbol\n";
		} else {
			print CSVOUT "$symbol" . "," . "$b_count" . "," . "$ms_rating" . "," . "$amt_outstanding" . "," . "$debtasset" . "," . "$comp_sector". "," . "$r_da_c" . "," . "$r_da_i" . "," . "$r_de_c" . "," . "$r_de_i" . "," . "$r_cacl_c" . "," . "$r_cacl_i" . "," . "$r_ebiti_c" . "," . "$r_ebiti_i" . "," . "$r_debit_c" . "," . "$r_debit_i" . "," . "$r_cfd_c" . "," . "$r_cfd_i" . "\n";
		}
		close (CSVOUT); 
	}
}
close (MYFILE);
