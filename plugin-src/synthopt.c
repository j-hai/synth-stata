#include <stdio.h>
#include <string.h>
#include <stdlib.h>     /* for malloc/calloc/free; <malloc.h> isn't portable
                         (no such header on macOS, where malloc is in stdlib.h) */
#include "pr_loqo.h"

#include "stplugin.h"

/* sprintf_s is a Microsoft-specific Annex K extension. The stdlib
   replacement is snprintf; same buffer-bounded semantics. */
#if !defined(_MSC_VER)
  #define sprintf_s(buf, sz, fmt, ...) snprintf((buf), (sz), (fmt), __VA_ARGS__)
#endif

#define ERROR_READ_STATA			201
#define ERROR_H_NOT_SYMMETRIC		202
#define ERROR_H_C_INCOMPATIBLE		203
#define ERROR_H_A_INCOMPATIBLE		204
#define ERROR_A_b_INCOMPATIBLE		205
#define ERROR_H_l_INCOMPATIBLE		207
#define ERROR_H_u_INCOMPATIBLE		208
#define ERROR_BOUND_SCALAR			209
#define ERROR_MAXITER_SCALAR		210
#define ERROR_MARGIN_SCALAR			211
#define ERROR_SIGF_SCALAR			212


int ReadMatrixFromStata(char* arg, ST_double * matrixout, ST_int row, ST_int col, int verbose);
#define ALLOC_AND_READ_FROM_STATA(arg,var,row,col, retVal)	{row = SF_row(arg);  col = SF_col(arg);if (row * col == 0) return ERROR_READ_STATA; var = calloc(col * row, sizeof(ST_double));retVal = ReadMatrixFromStata(arg,var,row,col,0);}

                                                              

STDLL stata_call(int argc, char *argv[])
{

	int m,n;
	ST_int row, col;
	//check correct number and type of args
	ST_double *c;//[n];   //arg0
	ST_double *H;//[n*n]; //arg1
	ST_double *A;//[n];  //arg2
	ST_double *b;//[1]; //arg3
	ST_double *l;//[n]; //arg4
	ST_double *u;//[n]; //arg5
	ST_double *dbound;	int bound; //arg6
	ST_double *margin; //arg7
	ST_double *dmaxiter; int maxiter; //arg8
	ST_double *sigf; //arg9
	int retVal;

	double *primal;//[3*38]; //result (vector of W weights)
	double *dual;//[1+(2*38)]; //result that gets ignored (dual solution)

	int loqo_return;
	int i;

	ALLOC_AND_READ_FROM_STATA(argv[1],H,row,col,retVal);	//read in H matrix
	//sanity check on H
	n=col;
	if (n != row)
	{
		SF_error("H matrix is not symmetric\n");
		return ERROR_H_NOT_SYMMETRIC;
	}

	ALLOC_AND_READ_FROM_STATA(argv[0],c,row,col,retVal);	//read in c vector
	if (n != row)
	{
		SF_error("H and c are incompatible\n");
		return ERROR_H_C_INCOMPATIBLE;
	//second dimension of c not checked
	}

	ALLOC_AND_READ_FROM_STATA(argv[2],A,row,col,retVal);	//read in A vector
	m=row;
	if (n != col)
	{
		SF_error("A is incompatible with H & c\n");
		return ERROR_H_A_INCOMPATIBLE;
	}

	ALLOC_AND_READ_FROM_STATA(argv[3],b,row,col,retVal);	//read in b value
	if (m != (row * col))
	{
		SF_error("b is incompatible with A & c\n");
		return ERROR_A_b_INCOMPATIBLE;
	}

	ALLOC_AND_READ_FROM_STATA(argv[4],l,row,col,retVal);	//read in l vector
	if (n != (row * col))
	{
		SF_error("l is incompatible with H & c & A");
		return ERROR_H_l_INCOMPATIBLE;
	}

	ALLOC_AND_READ_FROM_STATA(argv[5],u,row,col,retVal);	//read in u vector
	if (n != (row * col))
	{
		SF_error("u is incompatible with H & c & A & l");
		return ERROR_H_u_INCOMPATIBLE;
	}
	ALLOC_AND_READ_FROM_STATA(argv[6],dbound,row,col,retVal); bound = (int) *dbound;	//read in bound value
	if (1 != (row * col))
	{
		SF_error("bound should be a 1x1 matrix and an integer value");
		return ERROR_BOUND_SCALAR;
	}
	ALLOC_AND_READ_FROM_STATA(argv[7],margin,row,col,retVal);	//read in margin value
	if (1 != (row * col))
	{
		SF_error("margin should be a 1x1 matrix");
		return ERROR_MARGIN_SCALAR;
	}

	ALLOC_AND_READ_FROM_STATA(argv[8],dmaxiter,row,col,retVal); maxiter = (int)*dmaxiter;//read in maxiter value
	if (1 != (row * col))
	{
		SF_error("dmaxiter should be a 1x1 matrix and an integer value");
		return ERROR_MAXITER_SCALAR;
	}
	ALLOC_AND_READ_FROM_STATA(argv[9],sigf,row,col,retVal);//read in sigf value
	if (1 != (row * col))
	{
		SF_error("sigf should be a 1x1 matrix");
		return ERROR_SIGF_SCALAR;
	}

	row = SF_row(argv[10]);
	if (row != n)
	{
		SF_error("solution matrix is incompatible with H");
		return ERROR_SIGF_SCALAR;
	}
	
	primal = calloc(n * 3, sizeof(ST_double));
	dual = calloc(m + (n * 2), sizeof(ST_double));

	SF_display("starting quadratic optimization\n");
	loqo_return = pr_loqo(n,m,c,H,A,b,l,u,primal,dual,2,*sigf,maxiter,*margin,bound,0);


	//output to wsol
	SF_display("saving matrix\n");
	for(i=0;i<n;i++) 
	{
		SF_mat_store(argv[10],i+1,1,primal[i]);
	}
	SF_display("done\n");

	return(0) ;

}
/*
arrays in pr_loqo are as follows
A[i][j] on a qxr matrix is A[(r*i)+j]
in other words, the matrix:

row1
row2
row3

is stored as row1 row2 row3
*/

int ReadMatrixFromStata(char* arg, ST_double * matrixout, ST_int row, ST_int col, int verbose)
{

	int retVal;
	ST_ubyte toOutput[80];

	//todo: what if arg is greater than 80?
	//todo: what if not a matrix?
	int	i,j;

	if (verbose)
	{
		SF_display("reading in matrix "); SF_display(arg);SF_display("\n");
		sprintf_s(toOutput,80,"Number of Rows: %d \n",row);
		SF_display(toOutput);
		sprintf_s(toOutput,80,"Number of Column: %d \n",col);
		SF_display(toOutput);
	}

	for (i=0;i<col;i++) 
	{
		for(j=0;j<row;j++)	
		{
		  retVal = SF_mat_el(arg,j+1,i+1,matrixout);
		  if (retVal != 0)
		  {
			sprintf_s(toOutput,80,". function SF_mat_el returned error code %d on (%d,%d)\n",retVal, row,col);
			SF_error("var: ");SF_error(arg);SF_error(toOutput);
			return retVal;
		  }
		  matrixout++;
		}
		if (verbose)
		{
			SF_display("read in a row\n");
		}
	}
	if (verbose)
	{
		sprintf_s(toOutput,80,"Last number in matrix: %.5f \n",matrixout);
		SF_display(toOutput);
	}
	return 0;
}
