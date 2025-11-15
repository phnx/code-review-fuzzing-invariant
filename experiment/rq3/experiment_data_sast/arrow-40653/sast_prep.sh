#!/bin/bash

# clone target repo
rm -rf /experiment/repo
mkdir -p /experiment/repo

git clone --no-checkout https://github.com/apache/arrow.git $BIC_REPOSITORY_PATH 

# install and build dependencies
apt-get install -y -q --no-install-recommends \
	        bison \
		        build-essential \
			        flex \
				        libboost-all-dev \
					        ninja-build \
						        unzip

# checkout BIC
git -C $BIC_REPOSITORY_PATH checkout 3c5b62c116733e434508a8673c2d466776b27eed

# pre-compilation steps
rm -rf /workdir/arrow_build
mkdir -p /workdir/arrow_build

cd /workdir/arrow_build
ARROW=$BIC_REPOSITORY_PATH/cpp

CMAKE_POLICY_VERSION_MINIMUM=3.5 cmake ${ARROW} -GNinja \
	    -DCMAKE_BUILD_TYPE=Debug \
	        -DARROW_DEPENDENCY_SOURCE=BUNDLED \
		    -DBOOST_SOURCE=SYSTEM \
		        -DCMAKE_C_FLAGS="${CFLAGS}" \
			    -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
			        -DARROW_EXTRA_ERROR_CONTEXT=off \
				    -DARROW_JEMALLOC=off \
				        -DARROW_MIMALLOC=off \
					    -DARROW_FILESYSTEM=off \
					        -DARROW_PARQUET=on \
						    -DARROW_BUILD_SHARED=off \
						        -DARROW_BUILD_STATIC=on \
							    -DARROW_BUILD_TESTS=off \
							        -DARROW_BUILD_INTEGRATION=off \
								    -DARROW_BUILD_BENCHMARKS=off \
								        -DARROW_BUILD_EXAMPLES=off \
									    -DARROW_BUILD_UTILITIES=off \
									        -DARROW_TEST_LINKAGE=static \
										    -DPARQUET_BUILD_EXAMPLES=off \
										        -DPARQUET_BUILD_EXECUTABLES=off \
											    -DPARQUET_REQUIRE_ENCRYPTION=off \
											        -DARROW_WITH_BROTLI=on \
												    -DARROW_WITH_BZ2=off \
												        -DARROW_WITH_LZ4=off \
													    -DARROW_WITH_SNAPPY=on \
													        -DARROW_WITH_ZLIB=on \
														    -DARROW_WITH_ZSTD=on \
														        -DARROW_USE_GLOG=off \
															    -DARROW_USE_ASAN=off \
															        -DARROW_USE_UBSAN=off \
																    -DARROW_USE_TSAN=off \
																        -DARROW_FUZZING=off
