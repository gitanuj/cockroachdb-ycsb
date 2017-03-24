//
// Calculates 'x' for using lease-holder for reads
// Usage: go run lhfallback-prob.go <num_nodes>
// Current implementation divides requests equally
//

package main

import (
	"fmt"
	"os"
	"strconv"
)

// returns ratio of requests which should fallback to lease holder
func ratio(n int) float64 {
	P := Pquorum(n)
	return P * float64(n-2) / (float64(n) + P*float64(n-2))
}

// returns probability of being included in the quorum
func Pquorum(n int) float64 {
	if n <= 3 {
		return 1
	}
	num := nCr(n-3, n/2-1)
	den := nCr(n-2, n/2)
	return float64(num) / float64(den)
}

// a naive implementation of nCr for small values of n
func nCr(n int, r int) int {
	result := 1
	if r > n/2 {
		r = n - r
	}
	for i := 1; i <= r; i++ {
		result *= n - r + i
		result /= i
	}
	return result
}

func main() {
	n, _ := strconv.Atoi(os.Args[1])
	fmt.Println(ratio(n))
}
