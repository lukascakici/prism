// Prism Go sample.
//
// Exercises:
//   - package, import (grouped)
//   - struct / interface
//   - methods with pointer/value receivers
//   - goroutines, channels, select
//   - raw strings (`...`), interpolation via fmt
//   - rune literals ('x')
//   - generics (Go 1.18+)

package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"sort"
	"sync"
	"time"
)

// -----------------------------------------------------------------------------
// Constants — every literal form Go supports.
// -----------------------------------------------------------------------------

const (
	PI         float64 = 3.14159_26535
	HexMask    uint32  = 0xDEAD_BEEF
	Octal      int     = 0o755
	Binary     int     = 0b1010_1010
	Scientific float64 = 6.022e23
	NewlineCh  rune    = '\n'
	UnicodeCh  rune    = 'é'
)

// -----------------------------------------------------------------------------
// Types
// -----------------------------------------------------------------------------

type Shape interface {
	Area() float64
	Kind() string
}

type Circle struct {
	Radius float64
}

func (c Circle) Area() float64 { return PI * c.Radius * c.Radius }
func (c Circle) Kind() string  { return "circle" }

type Rect struct {
	Width, Height float64
}

func (r *Rect) Area() float64 { return r.Width * r.Height }
func (r *Rect) Kind() string  { return "rect" }

// Generic constraint
type Numeric interface {
	~int | ~int64 | ~float32 | ~float64
}

func SumOfSquares[T Numeric](values []T) T {
	var total T
	for _, v := range values {
		total += v * v
	}
	return total
}

// -----------------------------------------------------------------------------
// Worker pool with channels + select
// -----------------------------------------------------------------------------

func computeSquares(ctx context.Context, in <-chan int, out chan<- int, wg *sync.WaitGroup) {
	defer wg.Done()
	for {
		select {
		case <-ctx.Done():
			return
		case v, ok := <-in:
			if !ok {
				return
			}
			out <- v * v
		}
	}
}

// -----------------------------------------------------------------------------
// main
// -----------------------------------------------------------------------------

func main() {
	banner := `
Prism Go sample
===============
version : 1.0
mask    : 0xDEADBEEF
`
	fmt.Print(banner)

	shapes := []Shape{
		Circle{Radius: 2.0},
		&Rect{Width: 3.0, Height: 4.0},
	}
	sort.SliceStable(shapes, func(i, j int) bool { return shapes[i].Area() < shapes[j].Area() })

	for _, s := range shapes {
		fmt.Printf("%s: area=%.3f\n", s.Kind(), s.Area())
	}

	fmt.Printf("sum of squares: %d\n", SumOfSquares([]int{1, 2, 3, 4, 5}))

	// Goroutines + channels
	ctx, cancel := context.WithTimeout(context.Background(), 100*time.Millisecond)
	defer cancel()

	in := make(chan int)
	out := make(chan int)
	var wg sync.WaitGroup
	wg.Add(2)
	go computeSquares(ctx, in, out, &wg)
	go computeSquares(ctx, in, out, &wg)

	go func() {
		defer close(in)
		for i := 1; i <= 5; i++ {
			in <- i
		}
	}()

	go func() {
		wg.Wait()
		close(out)
	}()

	results := make([]int, 0, 5)
	for v := range out {
		results = append(results, v)
	}
	fmt.Println("squares =", results)

	if err := mightFail(); err != nil {
		log.Printf("warning: %v\n", err)
	}
}

func mightFail() error {
	return fmt.Errorf("not really an error: %w", errors.New("stub"))
}
