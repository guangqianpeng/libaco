#include "aco.h"
#include <benchmark/benchmark.h>
#include <vector>
#include <alloca.h>
// #include "aco_assert_override.h"


void co_fp_empty(){
    aco_exit();
}

void co_fp_alloca(){
    size_t sz = (size_t)((uintptr_t)aco_get_arg());
    if (sz > 0) {
        void* ptr = alloca(sz);
        benchmark::DoNotOptimize(ptr);
    }
    while(1){
        aco_yield();
    }
    aco_exit();
}

static void BM_aco_create(benchmark::State &state){
    aco_t *main_co = aco_create(NULL, NULL, 0, NULL, NULL);
    aco_share_stack_t* sstk = aco_share_stack_new(0);

    for (auto _ : state) {
        aco_t* co = aco_create(main_co, sstk, 0, co_fp_empty, NULL);
        benchmark::DoNotOptimize(co);
        aco_destroy(co);
    }

    aco_share_stack_destroy(sstk);
    aco_destroy(main_co);
}
BENCHMARK(BM_aco_create);

class AcoFixture : public benchmark::Fixture {
public:
    void SetUp(const ::benchmark::State& state) {
        main_co = aco_create(NULL, NULL, 0, NULL, NULL);
        sstk = aco_share_stack_new(0);

        co_amount = (size_t)state.range(0);
        co_stksz = (size_t)state.range(1);

        co_array.resize(co_amount);
        for (size_t i = 0; i < co_amount; i++) {
            co_array[i] = aco_create(main_co, sstk, 0, 
                                    co_fp_alloca, 
                                    (void*)((uintptr_t)co_stksz));
        }

        // warm up
        for (aco_t* co: co_array)
            aco_resume(co);
    }
    
    void TearDown(const ::benchmark::State& state) {
        for (aco_t* co: co_array)
            aco_destroy(co);

        aco_share_stack_destroy(sstk);
        aco_destroy(main_co);
    }

    aco_t* main_co = NULL;
    aco_share_stack_t* sstk = NULL;
    size_t co_amount = 0;
    size_t co_stksz = 0;
    std::vector<aco_t*> co_array;
};

BENCHMARK_DEFINE_F(AcoFixture, BM_bench_overhead)(benchmark::State &state) {
    size_t i = 0;
    for (auto _ : state) {
        i++;
        if (i >= co_amount)
            i -= co_amount;
    }
    benchmark::DoNotOptimize(i);
    state.SetLabel("benchmark overhead");
}
BENCHMARK_REGISTER_F(AcoFixture, BM_bench_overhead)->Args({1000000, 1});

BENCHMARK_DEFINE_F(AcoFixture, BM_aco_resume)(benchmark::State &state) {
    size_t i = 0;
    for (auto _ : state) {
        aco_resume(co_array[i]);
        i++;
        if (i >= co_amount)
            i -= co_amount;
        benchmark::DoNotOptimize(i);
    }

    char output[1024];
    sprintf(output, "aco_amount=%7zu copy_stack_size=%4zuB", 
            co_amount, co_array[0]->save_stack.max_cpsz);
    state.SetLabel(output);
}
BENCHMARK_REGISTER_F(AcoFixture, BM_aco_resume)->RangeMultiplier(10)
                                               ->Ranges({{1, 1000000}, {1, 1<<10}});

int main(int argc, char** argv) {
    aco_thread_init(NULL);
    ::benchmark::Initialize(&argc, argv);
    if (::benchmark::ReportUnrecognizedArguments(argc, argv))
        return 1;
    ::benchmark::RunSpecifiedBenchmarks();                         
}                                                                     
