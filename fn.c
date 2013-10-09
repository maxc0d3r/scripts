#include<stdio.h>

long int findn(unsigned long int,unsigned long int);

main()
{
	unsigned long int T=0,C=0,P=0;
	long int n=-1;
	long int cnt1;	
	scanf("%lu",&T);
	for(cnt1 = 1;cnt1 <= T;cnt1++)
	{	
		scanf("%lu %lu",&C,&P);
		n=findn(C,P);
		printf("%ld\n",n);		
	}		
	return 0;
}

long int findn(unsigned long int c,unsigned long int p)
{
	long int n = -1;
	unsigned long int xp2=5,xp1=8,x=1;
	long int cnt1;
	switch(c)
	{	
		case 0:
			n = 0;
			break;
		case 1:
			n = 1;
			break;
		case 2:
			n = 3;
			break;
		case 3:
			n = 4;
			break;
		case 5:
			n = 5;
			break;
		case 8:
			n = 6;
			break;
		default:		
			for(cnt1 = 7;;cnt1++)
			{		
				x=xp2+xp1;		
				if(x>=p)
					x=x%p;				
				xp2=xp1;
				xp1=x;
				if((xp2==1)&&(xp1==0))
					break;		
				else
				{				
					if(x==c)
					{
						n=cnt1;
						break;	
					}
				}
			}
	}	
	return n;
}
