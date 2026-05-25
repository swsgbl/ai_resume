package benchmark

import std.testing.*
import utils.crypto.CryptoUtils
import utils.crypto.OptimizedCryptoUtils
import services.TokenManager
import services.TokenManagerOptimized
import std.time.StopWatch

/**
 * 性能基准测试
 * 比较原始版本和优化版本的性能差异
 */
class PerformanceBenchmark {
    private let originalCrypto: CryptoUtils
    private let optimizedCrypto: OptimizedCryptoUtils
    private let iterations: Int = 1000

    public init() {
        this.originalCrypto = CryptoUtils()
        this.optimizedCrypto = OptimizedCryptoUtils()
    }

    /**
     * 加密性能基准测试
     */
    @Test
    func benchmarkEncryption() {
        let testData = "This is a test string for encryption performance benchmarking purposes."
        let originalTimes = ArrayList<Int64>()
        let optimizedTimes = ArrayList<Int64>()

        // 预热
        for (i in 0..100) {
            let _ = this.originalCrypto.encrypt(testData)
            let _ = this.optimizedCrypto.encryptOptimized(testData)
        }

        // 测试原始版本
        let stopWatch1 = StopWatch()
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            let _ = this.originalCrypto.encrypt(testData)
            let end = System.nanoTime()
            originalTimes.add(end - start)
        }

        // 测试优化版本
        let stopWatch2 = StopWatch()
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            let _ = this.optimizedCrypto.encryptOptimized(testData)
            let end = System.nanoTime()
            optimizedTimes.add(end - start)
        }

        // 计算统计数据
        let originalAvg = this.calculateAverage(originalTimes)
        let optimizedAvg = this.calculateAverage(optimizedTimes)
        let improvement = this.calculateImprovement(originalAvg, optimizedAvg)

        // 输出结果
        console.log("=== 加密性能基准测试 ===")
        console.log("原始版本平均时间: ${originalAvg} ns")
        console.log("优化版本平均时间: ${optimizedAvg} ns")
        console.log("性能提升: ${improvement}%")

        // 断言优化版本至少快10%
        Assert.assertTrue(improvement > 10, "优化版本应该至少快10%")
    }

    /**
     * 解密性能基准测试
     */
    @Test
    func benchmarkDecryption() {
        let testData = "This is a test string for decryption performance benchmarking purposes."
        let encryptedOriginal = this.originalCrypto.encrypt(testData)
        let encryptedOptimized = this.optimizedCrypto.encryptOptimized(testData)

        let originalTimes = ArrayList<Int64>()
        let optimizedTimes = ArrayList<Int64>()

        // 预热
        for (i in 0..100) {
            let _ = this.originalCrypto.decrypt(encryptedOriginal)
            let _ = this.optimizedCrypto.decryptOptimized(encryptedOptimized)
        }

        // 测试原始版本
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            let _ = this.originalCrypto.decrypt(encryptedOriginal)
            let end = System.nanoTime()
            originalTimes.add(end - start)
        }

        // 测试优化版本
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            let _ = this.optimizedCrypto.decryptOptimized(encryptedOptimized)
            let end = System.nanoTime()
            optimizedTimes.add(end - start)
        }

        // 计算统计数据
        let originalAvg = this.calculateAverage(originalTimes)
        let optimizedAvg = this.calculateAverage(optimizedTimes)
        let improvement = this.calculateImprovement(originalAvg, optimizedAvg)

        // 输出结果
        console.log("=== 解密性能基准测试 ===")
        console.log("原始版本平均时间: ${originalAvg} ns")
        console.log("优化版本平均时间: ${optimizedAvg} ns")
        console.log("性能提升: ${improvement}%")

        // 断言优化版本至少快10%
        Assert.assertTrue(improvement > 10, "优化版本应该至少快10%")
    }

    /**
     * 哈希性能基准测试
     */
    @Test
    func benchmarkHashing() {
        let testData = "This is a test string for hashing performance benchmarking purposes."
        let originalTimes = ArrayList<Int64>()
        let optimizedTimes = ArrayList<Int64>()

        // 预热
        for (i in 0..100) {
            let _ = this.originalCrypto.hash(testData)
            let _ = this.optimizedCrypto.hashOptimized(testData)
        }

        // 测试原始版本
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            let _ = this.originalCrypto.hash(testData)
            let end = System.nanoTime()
            originalTimes.add(end - start)
        }

        // 测试优化版本
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            let _ = this.optimizedCrypto.hashOptimized(testData)
            let end = System.nanoTime()
            optimizedTimes.add(end - start)
        }

        // 计算统计数据
        let originalAvg = this.calculateAverage(originalTimes)
        let optimizedAvg = this.calculateAverage(optimizedTimes)
        let improvement = this.calculateImprovement(originalAvg, optimizedAvg)

        // 输出结果
        console.log("=== 哈希性能基准测试 ===")
        console.log("原始版本平均时间: ${originalAvg} ns")
        console.log("优化版本平均时间: ${optimizedAvg} ns")
        console.log("性能提升: ${improvement}%")

        // 断言优化版本至少快15%
        Assert.assertTrue(improvement > 15, "优化版本应该至少快15%")
    }

    /**
     * 批量哈希性能基准测试
     */
    @Test
    func benchmarkBatchHashing() {
        let testData = Array<String>()
        for (i in 0..100) {
            testData.add("test data ${i} for batch hashing benchmark")
        }

        // 测试原始版本（串行处理）
        let start1 = System.nanoTime()
        for (data in testData) {
            let _ = this.originalCrypto.hash(data)
        }
        let originalTime = System.nanoTime() - start1

        // 测试优化版本（并行处理）
        let start2 = System.nanoTime()
        let _ = this.optimizedCrypto.hashBatch(inputs: testData)
        let optimizedTime = System.nanoTime() - start2

        let improvement = this.calculateImprovement(originalTime, optimizedTime)

        // 输出结果
        console.log("=== 批量哈希性能基准测试 ===")
        console.log("数据量: ${testData.size()}")
        console.log("原始版本总时间: ${originalTime} ns")
        console.log("优化版本总时间: ${optimizedTime} ns")
        console.log("性能提升: ${improvement}%")

        // 断言优化版本至少快30%（并行处理优势）
        Assert.assertTrue(improvement > 30, "批量处理应该至少快30%")
    }

    /**
     * 内存使用基准测试
     */
    @Test
    func benchmarkMemoryUsage() {
        let runtime = Runtime.getRuntime()

        // 测试原始版本内存使用
        runtime.gc()
        let memoryBefore1 = runtime.totalMemory() - runtime.freeMemory()

        for (i in 0..1000) {
            let _ = this.originalCrypto.encrypt("test data for memory benchmark ${i}")
        }

        runtime.gc()
        let memoryAfter1 = runtime.totalMemory() - runtime.freeMemory()
        let originalMemoryUsage = memoryAfter1 - memoryBefore1

        // 测试优化版本内存使用
        runtime.gc()
        let memoryBefore2 = runtime.totalMemory() - runtime.freeMemory()

        for (i in 0..1000) {
            let _ = this.optimizedCrypto.encryptOptimized("test data for memory benchmark ${i}")
        }

        runtime.gc()
        let memoryAfter2 = runtime.totalMemory() - runtime.freeMemory()
        let optimizedMemoryUsage = memoryAfter2 - memoryBefore2

        let memoryImprovement = this.calculateImprovement(originalMemoryUsage, optimizedMemoryUsage)

        // 输出结果
        console.log("=== 内存使用基准测试 ===")
        console.log("原始版本内存使用: ${originalMemoryUsage} bytes")
        console.log("优化版本内存使用: ${optimizedMemoryUsage} bytes")
        console.log("内存节省: ${memoryImprovement}%")

        // 断言优化版本至少节省20%内存
        Assert.assertTrue(memoryImprovement > 20, "优化版本应该至少节省20%内存")
    }

    /**
     * TokenManager性能基准测试
     */
    @Test
    func benchmarkTokenManager() {
        let context = MockContext()
        let originalManager = TokenManager(context)
        let optimizedManager = TokenManagerOptimized(context)

        let testToken = "test_access_token_for_benchmarking_purposes"

        // 预热
        for (i in 0..100) {
            originalManager.saveAccessToken(testToken)
            let _ = originalManager.getAccessToken()
            optimizedManager.saveAccessToken(testToken)
            let _ = optimizedManager.getAccessToken()
        }

        // 测试原始版本
        let originalTimes = ArrayList<Int64>()
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            originalManager.saveAccessToken(testToken)
            let _ = originalManager.getAccessToken()
            let end = System.nanoTime()
            originalTimes.add(end - start)
        }

        // 测试优化版本
        let optimizedTimes = ArrayList<Int64>()
        for (i in 0..this.iterations) {
            let start = System.nanoTime()
            optimizedManager.saveAccessToken(testToken)
            let _ = optimizedManager.getAccessToken()
            let end = System.nanoTime()
            optimizedTimes.add(end - start)
        }

        // 计算统计数据
        let originalAvg = this.calculateAverage(originalTimes)
        let optimizedAvg = this.calculateAverage(optimizedTimes)
        let improvement = this.calculateImprovement(originalAvg, optimizedAvg)

        // 输出结果
        console.log("=== TokenManager性能基准测试 ===")
        console.log("原始版本平均时间: ${originalAvg} ns")
        console.log("优化版本平均时间: ${optimizedAvg} ns")
        console.log("性能提升: ${improvement}%")

        // 断言优化版本至少快25%（内存缓存优势）
        Assert.assertTrue(improvement > 25, "TokenManager优化版本应该至少快25%")
    }

    /**
     * 并发性能基准测试
     */
    @Test
    func benchmarkConcurrency() {
        let testData = "concurrent test data"
        let threadCount = 10
        let operationsPerThread = 100

        // 测试原始版本并发性能
        let start1 = System.nanoTime()
        let threads1 = ArrayList<Thread>()
        for (i in 0..threadCount) {
            let thread = Thread({
                for (j in 0..operationsPerThread) {
                    let _ = this.originalCrypto.encrypt(testData)
                }
            })
            threads1.add(thread)
            thread.start()
        }

        for (thread in threads1) {
            thread.join()
        }
        let originalTime = System.nanoTime() - start1

        // 测试优化版本并发性能
        let start2 = System.nanoTime()
        let threads2 = ArrayList<Thread>()
        for (i in 0..threadCount) {
            let thread = Thread({
                for (j in 0..operationsPerThread) {
                    let _ = this.optimizedCrypto.encryptOptimized(testData)
                }
            })
            threads2.add(thread)
            thread.start()
        }

        for (thread in threads2) {
            thread.join()
        }
        let optimizedTime = System.nanoTime() - start2

        let improvement = this.calculateImprovement(originalTime, optimizedTime)

        // 输出结果
        console.log("=== 并发性能基准测试 ===")
        console.log("线程数: ${threadCount}, 每线程操作数: ${operationsPerThread}")
        console.log("原始版本总时间: ${originalTime} ns")
        console.log("优化版本总时间: ${optimizedTime} ns")
        console.log("性能提升: ${improvement}%")

        // 断言优化版本在并发场景下至少快40%
        Assert.assertTrue(improvement > 40, "并发场景下优化版本应该至少快40%")
    }

    /**
     * 计算平均值
     */
    private func calculateAverage(times: ArrayList<Int64>): Float {
        if (times.isEmpty()) {
            return 0.0f
        }

        var sum: Int64 = 0
        for (time in times) {
            sum += time
        }

        return sum.toFloat() / times.size().toFloat()
    }

    /**
     * 计算性能提升百分比
     */
    private func calculateImprovement(original: Float, optimized: Float): Float {
        if (original == 0.0f) {
            return 0.0f
        }

        return ((original - optimized) / original) * 100.0f
    }
}
