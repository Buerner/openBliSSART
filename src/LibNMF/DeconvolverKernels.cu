//
// This file is part of openBliSSART.
//
// Copyright (c) 2007-2011, Alexander Lehmann <lehmanna@in.tum.de>
//                          Felix Weninger <felix@weninger.de>
//                          Bjoern Schuller <schuller@tum.de>
//
// Institute for Human-Machine Communication
// Technische Universitaet Muenchen (TUM), D-80333 Munich, Germany
//
// openBliSSART is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 2 of the License, or (at your option) any later
// version.
//
// openBliSSART is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// openBliSSART.  If not, see <http://www.gnu.org/licenses/>.
//


#include <cuda.h>


namespace blissart {


namespace nmf {


namespace gpu {


int blocksize = 16;


__global__ void KLWUpdateKernel(const double *w, const double *wUpdateNum, const double *hRowSums, double* updatedW, int rows, int cols)
{
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int wIndex = col * rows + row;
    if(col < cols && row < rows) 
        updatedW[wIndex] = w[wIndex] * wUpdateNum[wIndex] / hRowSums[col];
}


void apply_KLWUpdate(const double* w, const double *wUpdateNum, const double *hRowSums, double* updatedW, int rows, int cols) {
    dim3 dimBlock(blocksize, blocksize);
    dim3 dimGrid(cols / dimBlock.x + 1, rows / dimBlock.y + 1);
    KLWUpdateKernel<<<dimGrid, dimBlock>>>(w, wUpdateNum, hRowSums, updatedW, rows, cols);
    cudaThreadSynchronize();
}


__global__ void KLHUpdateKernel(const double *hUpdateNum, const double *wColSums, double* hUpdate, int rows, int cols)
{
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int hIndex = col * rows + row;
    if(col < cols && row < rows) 
        hUpdate[hIndex] = hUpdateNum[hIndex] / wColSums[row];
}


void compute_KLHUpdate(const double *hUpdateNum, const double *wColSums, double* hUpdate, int rows, int cols) {
    dim3 dimBlock(blocksize, blocksize);
    dim3 dimGrid(cols / dimBlock.x + 1, rows / dimBlock.y + 1);
    KLHUpdateKernel<<<dimGrid, dimBlock>>>(hUpdateNum, wColSums, hUpdate, rows, cols);
    cudaThreadSynchronize();
}


}


}


}

