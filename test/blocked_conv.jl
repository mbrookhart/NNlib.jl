using BenchmarkTools
using Test
using NNlib
using LinearAlgebra

BLAS.set_num_threads(4)

function test_blocked_conv(im_size,
                           k_size,
                           rank,
                           pad,
                           stride,
                           dilation;
                           benchmark = false)
    X_shape = vcat([im_size for i in 1:rank], [32, 128])
    W_shape = vcat([k_size for i in 1:rank], [32, 16])

    X = rand(Float32, X_shape...)
    W = rand(Float32, W_shape...)

    bX = block(X, rank + 1)
    bW = block(block(W, rank + 1), rank + 3)


    if benchmark
        println("Data Shape: $(size(X))")
        println("Weight Shape: $(size(W))")
        println("pad=$pad, stride=$stride, dilation=$dilation")
        # print("block_data: ")
        # @btime block($X, $(rank + 1))
        # print("block_weights: ")
        # @btime block(block($W, $(rank + 1)), $(rank + 3))


        c = DenseConvDims(X, W; stride = stride, dilation = dilation, padding = pad)
        print("blocked_conv2d: ")
        @btime Out1 = blocked_conv($bX, $bW, $c)
        print("NNlib.conv: ")
        @btime Out2 = conv($X, $W, $c)
        println()
    end
    c = DenseConvDims(X, W; stride = stride, dilation = dilation, padding = pad)
    Out1 = blocked_conv(bX, bW, c)
    Out2 = conv(X, W, c)
    @test isapprox(deblock(Out1, rank + 1), Out2)
end

do_benchmarking = false

for im_size = [32, 64, 128, 192]
    for k_size = [5]
        for pad = [3], stride = [2], dilation = [2]
            test_blocked_conv(im_size, k_size, 1, pad, stride, dilation, benchmark = do_benchmarking)
            test_blocked_conv(im_size, k_size, 2, pad, stride, dilation, benchmark = do_benchmarking)
            if im_size <= 32
                test_blocked_conv(im_size, k_size, 3, pad, stride, dilation, benchmark = do_benchmarking)
            end
        end
    end
end