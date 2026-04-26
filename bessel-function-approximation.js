/**
 * 三次贝塞尔曲线拟合器 (Cubic Bezier Fitter) - 最终优化版
 * 增加自动精细化搜索，以获得更精确的 Flutter Cubic 参数。
 */

// --- 基础数学函数和线性代数 (用于最小二乘法) ---

function transpose(matrix) {
    // ... (保持不变)
    const rows = matrix.length;
    const cols = matrix[0].length;
    const result = [];
    for (let j = 0; j < cols; j++) {
        result[j] = [];
        for (let i = 0; i < rows; i++) {
            result[j][i] = matrix[i][j];
        }
    }
    return result;
}

function multiply(A, B) {
    // ... (保持不变)
    const rowsA = A.length;
    const colsA = A[0].length;
    const rowsB = B.length;
    const colsB = B[0].length;

    if (colsA !== rowsB) {
        throw new Error("矩阵尺寸不兼容进行乘法");
    }

    const C = new Array(rowsA).fill(0).map(() => new Array(colsB).fill(0));

    for (let i = 0; i < rowsA; i++) {
        for (let j = 0; j < colsB; j++) {
            let sum = 0;
            for (let k = 0; k < colsA; k++) {
                sum += A[i][k] * B[k][j];
            }
            C[i][j] = sum;
        }
    }
    return C;
}

function inverse2x2(M) {
    // ... (保持不变)
    const a = M[0][0];
    const b = M[0][1];
    const c = M[1][0];
    const d = M[1][1];
    const det = a * d - b * c;

    if (Math.abs(det) < 1e-12) {
        throw new Error("2x2 矩阵近似奇异，无法求逆");
    }

    const invDet = 1 / det;
    return [
        [d * invDet, -b * invDet],
        [-c * invDet, a * invDet]
    ];
}

// --- 贝塞尔拟合核心逻辑 ---

class BezierFitter {
    constructor(data) {
        this.data = data;
        this.xs = data.map(p => p.x);
        this.ys = data.map(p => p.y);
        this.max_x = Math.max(...this.xs);
        this.s = this.xs.map(x => x / this.max_x);
    }

    static bezier_x(t, x1, x2) {
        return 3 * (1 - t) ** 2 * t * x1 + 3 * (1 - t) * t ** 2 * x2 + t ** 3;
    }

    static bezier_y(t, y1, y2) {
        return 3 * (1 - t) ** 2 * t * y1 + 3 * (1 - t) * t ** 2 * y2 + t ** 3;
    }

    static solve_t_for_x(s_target, x1, x2) {
        let t = s_target;
        const maxIterations = 60;
        const tolerance = 1e-12;

        for (let i = 0; i < maxIterations; i++) {
            const x = BezierFitter.bezier_x(t, x1, x2);
            const dx_dt = 3 * (1 - t) ** 2 * x1 + 6 * (1 - t) * t * (x2 - x1) + 3 * t ** 2 * (1 - x2);

            if (Math.abs(dx_dt) < tolerance) {
                break;
            }

            const t_new = t - (x - s_target) / dx_dt;
            let t_clipped = Math.max(0, Math.min(1, t_new));

            if (Math.abs(t_clipped - t) < tolerance) {
                t = t_clipped;
                break;
            }
            t = t_clipped;
        }
        return t;
    }

    compute_p_for_control(x1, y1, x2, y2) {
        const p = [];
        for (const si of this.s) {
            const t = BezierFitter.solve_t_for_x(si, x1, x2);
            p.push(BezierFitter.bezier_y(t, y1, y2));
        }
        return p;
    }

    /**
     * @returns {{alpha: number, C: number, rmse: number, preds: number[], errors: number[]}} 拟合结果
     */
    fit_alpha_C(p) {
        const A = p.map(pi => [1 - pi, 1]);
        const y = this.ys.map(yi => [yi]); 

        const At = transpose(A); 
        const AtA = multiply(At, A); 
        
        try {
            const AtA_inv = inverse2x2(AtA);
            const AtA_inv_At = multiply(AtA_inv, At);
            const sol_matrix = multiply(AtA_inv_At, y);

            const alpha = sol_matrix[0][0];
            const C = sol_matrix[1][0];

            let sum_sq_error = 0;
            const preds = [];
            const errors = [];
            for (let i = 0; i < p.length; i++) {
                const pred = alpha * (1 - p[i]) + C;
                preds.push(pred);
                const error = this.ys[i] - pred;
                errors.push(error);
                sum_sq_error += error ** 2;
            }
            
            const rmse = Math.sqrt(sum_sq_error / preds.length);

            return { alpha, C, rmse, preds, errors };
        } catch (error) {
            return { alpha: 0, C: 0, rmse: Infinity, preds: [], errors: [] };
        }
    }

    /**
     * @param {number[]} gridX1, gridY1, gridX2, gridY2 - 搜索的网格点
     */
    run_grid_search(gridX1, gridY1, gridX2, gridY2) {
        let best = { rmse: Infinity };
        let count = 0;

        for (const x1 of gridX1) {
            for (const y1 of gridY1) {
                for (const x2 of gridX2) {
                    for (const y2 of gridY2) {
                        count++;
                        const p = this.compute_p_for_control(x1, y1, x2, y2);
                        const result = this.fit_alpha_C(p);

                        if (result.rmse < best.rmse) {
                            best = {
                                rmse: result.rmse,
                                x1, y1, x2, y2,
                                alpha: result.alpha,
                                C: result.C,
                                preds: result.preds,
                                errors: result.errors
                            };
                        }
                    }
                }
            }
        }
        return best;
    }
    
    /**
     * 自动执行粗搜索和精细化搜索
     */
    auto_fit() {
        // --- 第 1 步: 粗搜索 (步长 0.1) ---
        const coarseStep = 0.1;
        const gridCoarse = [];
        for (let v = 0; v <= 1.0 + 1e-9; v += coarseStep) {
            // 保持粗搜索精度为 3 位小数
            gridCoarse.push(Math.round(v * 1000) / 1000); 
        }

        console.log(`\n--- 步骤 1: 粗网格搜索 (步长: ${coarseStep}) ---`);
        const startTimeCoarse = Date.now();
        let bestResult = this.run_grid_search(gridCoarse, gridCoarse, gridCoarse, gridCoarse);
        const elapsedCoarse = (Date.now() - startTimeCoarse) / 1000;
        console.log(`粗搜索完成，耗时: ${elapsedCoarse.toFixed(2)} 秒。 最佳 RMSE: ${bestResult.rmse.toFixed(4)}`);


        // --- 第 2 步: 精细化搜索 (步长 0.001) ---
        // *** 关键修改: 将精细化步长减小到 0.001 ***
        const refinedStep = 0.001;
        const range = 0.01; // 在粗搜索最佳点的 +/- 0.01 范围内进行精细搜索 (范围减小以控制搜索量)

        const generateRefinedGrid = (val) => {
            const grid = [];
            // 确保起始点和结束点精确到 6 位小数，避免浮点数误差影响循环
            const start = Math.max(0, val - range);
            const end = Math.min(1, val + range);
            
            // 使用 for 循环和 toFixed 来精确控制步长
            for (let v = start; v <= end + refinedStep / 2; v += refinedStep) {
                // 将 v 四舍五入到 6 位小数再推入，确保网格点之间的间隔是精确的 0.001
                const v_rounded = Math.round(v * 1e6) / 1e6;
                grid.push(Math.max(0, Math.min(1, v_rounded)));
            }
            
            // 使用 Set 去重，并排序
            return Array.from(new Set(grid)).sort((a, b) => a - b);
        };

        const gridX1 = generateRefinedGrid(bestResult.x1);
        const gridY1 = generateRefinedGrid(bestResult.y1);
        const gridX2 = generateRefinedGrid(bestResult.x2);
        const gridY2 = generateRefinedGrid(bestResult.y2);

        console.log(`\n--- 步骤 2: 精细化网格搜索 (步长: ${refinedStep}) ---`);
        const startTimeRefined = Date.now();
        const bestRefined = this.run_grid_search(gridX1, gridY1, gridX2, gridY2);
        const elapsedRefined = (Date.now() - startTimeRefined) / 1000;
        console.log(`精细化搜索完成，耗时: ${elapsedRefined.toFixed(2)} 秒。 最佳 RMSE: ${bestRefined.rmse.toFixed(4)}`);
        
        return bestRefined;
    }
}

// --- 3. 实验数据 and 执行部分 ---

// 您的实验散点数据 (x-y)
const rawData = [
    { x: 0, y: 50 },
    { x: 1, y: 33 },
    { x: 2, y: 19 },
    { x: 3, y: 9 },
    { x: 4, y: 2 },
    { x: 5, y: -3 },
    { x: 6, y: -6 },
    { x: 7, y: -9 },
    { x: 8, y: -10 },
    { x: 11, y: -9 },
    { x: 13, y: -8 },
    { x: 18, y: -3 },
    { x: 21, y: -1 },
    { x: 23, y: 0 }
];


const fitter = new BezierFitter(rawData);
const finalResult = fitter.auto_fit(); // 运行自动两步搜索

// --- 最终输出结果，控制 Cubic 参数为三位小数 ---

// 再次四舍五入以确保最终输出的精度符合要求
const x1_3dp = finalResult.x1.toFixed(3);
const y1_3dp = finalResult.y1.toFixed(3);
const x2_3dp = finalResult.x2.toFixed(3);
const y2_3dp = finalResult.y2.toFixed(3);


console.log("\n=======================================================");
console.log("--- 最终最佳拟合结果 ---");
console.log("=======================================================");
// RMSE 和 线性模型参数继续使用 4 位小数以便于评估拟合质量
console.log(`最小均方根误差 (RMSE): ${finalResult.rmse.toFixed(4)}`);
console.log(`线性模型: Y = ${finalResult.alpha.toFixed(4)} * (1 - p) + ${finalResult.C.toFixed(4)}`);
console.log("----------------------------");

console.log("\n--- 数据点与拟合曲线的误差 (残差) ---");
console.log(" X   |  Y_实际  | Y_拟合 | 误差 (Y_实 - Y_拟)");
console.log("-----------------------------------------");
fitter.data.forEach((point, index) => {
    const predY = finalResult.preds[index];
    const error = finalResult.errors[index];
    console.log(
        `${String(point.x).padStart(3)} | ${String(point.y).padStart(8)} | ${predY.toFixed(3).padStart(6)} | ${error.toFixed(4).padStart(8)}`
    );
});
console.log("-----------------------------------------");

console.log("\n--- Flutter Cubic 曲线参数 (a, b, c, d) [精确到三位小数] ---");
// *** 关键修改: 这里使用 toFixed(3) 确保参数为三位小数 ***
console.log(`归一化控制点 P1 = (${x1_3dp}, ${y1_3dp})`);
console.log(`归一化控制点 P2 = (${x2_3dp}, ${y2_3dp})`);
console.log("\n请将以下参数直接复制到您的 Flutter 代码中：");
console.log(`const Cubic(\n  ${x1_3dp}, // a (P1.x)\n  ${y1_3dp}, // b (P1.y)\n  ${x2_3dp}, // c (P2.x)\n  ${y2_3dp}, // d (P2.y)\n);`);

console.log("\n--- 预压缩 Keyframe 数据 (归一化 Offset 列表) ---");
console.log("const [");

const startY = fitter.ys[0];
const endY = fitter.ys[fitter.ys.length - 1];
const totalDeltaY = endY - startY;

fitter.data.forEach((point, index) => {
    const nx = (point.x / fitter.max_x).toFixed(6);
    // 归一化 Y：相对于起点和终点的总变化量
    // 如果起点到终点的变化量不为 0，则按比例缩放，使得起点为 0，终点为 1
    let ny_val = totalDeltaY === 0 ? 0 : (point.y - startY) / totalDeltaY;
    
    const ny = ny_val.toFixed(6);
    process.stdout.write(`  Offset(${nx}, ${ny}),\n`);
});
console.log("];");
console.log("=======================================================");