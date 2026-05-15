#include <algorithm>
#include <chrono>
#include <cmath>
#include <iostream>
#include <random>
#include <string>
#include <unordered_map>
#include <vector>

// 全局变量防止优化
volatile double globalSink = 0.0;

// 随机数生成器
std::mt19937 rng(42); // 固定随机种子
std::uniform_real_distribution<double> dist(1.0, 100.0);

// 矩阵类型
using Matrix = std::vector<std::vector<double>>;

// ==================== 单操作函数 (每个函数内部循环 M 次) ====================
double testAdd(double a, double b, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += a + b;
    }
    globalSink += res;
    return res;
}

double testSub(double a, double b, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += a - b;
    }
    globalSink += res;
    return res;
}

double testMul(double a, double b, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += a * b;
    }
    globalSink += res;
    return res;
}

double testDiv(double a, double b, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += a / b;
    }
    globalSink += res;
    return res;
}

double testMulAdd(double a, double b, double c, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += a * b + c;
    }
    globalSink += res;
    return res;
}

double testDivAdd(double a, double b, double c, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += a / b + c;
    }
    globalSink += res;
    return res;
}

double testSqrt(double a, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::sqrt(a);
    }
    globalSink += res;
    return res;
}

double testPow(double a, double b, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::pow(a, b);
    }
    globalSink += res;
    return res;
}

double testLog(double a, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::log(a);
    }
    globalSink += res;
    return res;
}

double testExp(double a, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::exp(a);
    }
    globalSink += res;
    return res;
}

double testSin(double a, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::sin(a);
    }
    globalSink += res;
    return res;
}

double testCos(double a, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::cos(a);
    }
    globalSink += res;
    return res;
}

double testTan(double a, int M)
{
    double res = 0;
    for (int i = 0; i < M; ++i)
    {
        res += std::tan(a);
    }
    globalSink += res;
    return res;
}

// ==================== 矩阵函数 ====================
Matrix randomMatrix(int rows, int cols)
{
    Matrix mat(rows, std::vector<double>(cols));
    for (int i = 0; i < rows; ++i)
    {
        for (int j = 0; j < cols; ++j)
        {
            mat[i][j] = dist(rng);
        }
    }
    return mat;
}

Matrix matrixAdd(const Matrix& a, const Matrix& b, int M)
{
    size_t rows = a.size();
    size_t cols = a[0].size();
    Matrix c(rows, std::vector<double>(cols, 0.0));

    for (size_t m = 0; m < M; ++m)
    {
        for (size_t i = 0; i < rows; ++i)
        {
            for (size_t j = 0; j < cols; ++j)
            {
                c[i][j] = a[i][j] + b[i][j];
            }
        }
    }

    double total = 0;
    for (auto& row : c)
    {
        for (auto& val : row)
        {
            total += val;
        }
    }
    globalSink += total;
    return c;
}

Matrix matrixMul(const Matrix& a, const Matrix& b, int M)
{
    size_t rows = a.size();
    size_t cols = b[0].size();
    size_t k    = b.size();
    Matrix c(rows, std::vector<double>(cols, 0.0));

    for (size_t m = 0; m < M; ++m)
    {
        for (size_t i = 0; i < rows; ++i)
        {
            for (size_t j = 0; j < cols; ++j)
            {
                double sum = 0;
                for (size_t l = 0; l < k; ++l)
                {
                    sum += a[i][l] * b[l][j];
                }
                c[i][j] = sum;
            }
        }
    }

    double total = 0;
    for (auto& row : c)
    {
        for (auto& val : row)
        {
            total += val;
        }
    }
    globalSink += total;
    return c;
}

// ==================== 测试函数模板 ====================
template <typename Func, typename... Args>
double measureTime(Func f, int n, Args&&... args)
{
    using namespace std::chrono;
    auto start = high_resolution_clock::now();
    for (int i = 0; i < n; ++i)
    {
        f(std::forward<Args>(args)...);
    }
    auto end = high_resolution_clock::now();
    return duration<double, std::micro>(end - start).count() / n;
}

// ==================== 主函数 ====================
int main()
{
    const int n = 1000;  // 外层循环次数
    const int m = 10000; // 每个函数内部循环次数
    std::unordered_map<std::string, double> results;

    double a = dist(rng);
    double b = dist(rng);
    double c = dist(rng);

    Matrix matA = randomMatrix(50, 50);
    Matrix matB = randomMatrix(50, 50);

    // 基本运算
    results["+"]  = measureTime(testAdd, n, a, b, m);
    results["-"]  = measureTime(testSub, n, a, b, m);
    results["*"]  = measureTime(testMul, n, a, b, m);
    results["/"]  = measureTime(testDiv, n, a, b, m);
    results["*+"] = measureTime(testMulAdd, n, a, b, c, m);
    results["/+"] = measureTime(testDivAdd, n, a, b, c, m);

    // 数学函数
    results["sqrt"] = measureTime(testSqrt, n, a, m);
    results["pow"]  = measureTime(testPow, n, a, b, m);
    results["log"]  = measureTime(testLog, n, a, m);
    results["exp"]  = measureTime(testExp, n, a, m);
    results["sin"]  = measureTime(testSin, n, a, m);
    results["cos"]  = measureTime(testCos, n, a, m);
    results["tan"]  = measureTime(testTan, n, a, m);

    // 矩阵运算
    results["matrix_add"] = measureTime(matrixAdd, 10, matA, matB, 10);
    results["matrix_mul"] = measureTime(matrixMul, 5, matA, matB, 5);

    // 输出结果
    std::cout << "Average execution time (microseconds):\n";
    for (auto& [name, time] : results)
    {
        std::cout << name << ": " << time << " us\n";
    }

    // 输出 globalSink 防止优化
    std::cout << "Global sink (to prevent optimization): " << globalSink << std::endl;

    return 0;
}