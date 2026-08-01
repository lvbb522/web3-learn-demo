package main

import (
	"fmt"
	"math"
	"sync"
	"sync/atomic"
	"time"
)

// 1. 编写一个Go程序，定义一个函数，该函数接收一个整数指针作为参数，在函数内部将该指针指向的值增加10，然后在主函数中调用该函数并输出修改后的值。
func addTen(p *int) {
	*p = *p + 10
}

// 2.实现一个函数，接收一个整数切片的指针，将切片中的每个元素乘以2。
func f2(p *[]int) {
	if p == nil {
		return
	}
	for index, v := range *p {
		(*p)[index] = v * 2
	}
}

// 3.编写一个程序，使用 go 关键字启动两个协程，一个协程打印从1到10的奇数，另一个协程打印从2到10的偶数。
func f3() {
	var wg sync.WaitGroup

	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 1; i <= 10; i += 2 {
			fmt.Println("奇数:", i)
			time.Sleep(time.Microsecond)
		}
	}()

	wg.Add(1)
	go func() {
		defer wg.Done()
		for i := 2; i <= 10; i += 2 {
			fmt.Println("偶数:", i)
			time.Sleep(time.Microsecond)
		}
	}()

	wg.Wait()
}

// 5.定义一个 Shape 接口，包含 Area() 和 Perimeter() 两个方法。然后创建 Rectangle 和 Circle 结构体，实现 Shape 接口。在主函数中，创建这两个结构体的实例，并调用它们的 Area() 和 Perimeter() 方法。
// 考察点 ：接口的定义与实现、面向对象编程风格。
type Shape interface {
	Area() float64
	Perimeter() float64
}

type Rectangle struct {
	Width, Height float64
}

func (r Rectangle) Area() float64 {
	return r.Width * r.Height
}

func (r Rectangle) Perimeter() float64 {
	return 2 * (r.Width + r.Height)
}

type Circle struct {
	Radius float64
}

func (c Circle) Area() float64 {
	return math.Pi * c.Radius * c.Radius
}

func (c Circle) Perimeter() float64 {
	return 2 * math.Pi * c.Radius
}

func PrintShapeInfo(s Shape) {
	fmt.Printf("Area: %.2f, Perimeter: %.2f\n",
		s.Area(), s.Perimeter())
}

// 6.使用组合的方式创建一个 Person 结构体，包含 Name 和 Age 字段，再创建一个 Employee 结构体，组合 Person 结构体并添加 EmployeeID 字段。
// 为 Employee 结构体实现一个 PrintInfo() 方法，输出员工的信息。
// 考察点 ：组合的使用、方法接收者。

type Person struct {
	Name string
	Age  int
}

type Employee struct {
	Ps Person
	ID string
}

func (e Employee) PrintInfo() {
	fmt.Printf("ID: %s, %s, %d", e.ID, e.Ps.Name, e.Ps.Age)
}

// 7.题目 ：编写一个程序，使用通道实现两个协程之间的通信。一个协程生成从1到10的整数，并将这些整数发送到通道中，另一个协程从通道中接收这些整数并打印出来。
// 考察点 ：通道的基本使用、协程间通信。
func f7() {
	ch := make(chan int)

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		defer close(ch)
		for i := 1; i <= 10; i++ {
			ch <- i
		}
	}()

	go func() {
		defer wg.Done()
		for v := range ch {
			fmt.Println(v)
		}
	}()
	wg.Wait()
}

// 8.题目 ：实现一个带有缓冲的通道，生产者协程向通道中发送100个整数，消费者协程从通道中接收这些整数并打印。
// 考察点 ：通道的缓冲机制。
func f8() {
	ch := make(chan int, 5)

	var wg sync.WaitGroup
	wg.Add(2)

	go func() {
		defer wg.Done()
		defer close(ch)
		for i := 1; i <= 100; i++ {
			ch <- i
		}
	}()

	go func() {
		defer wg.Done()
		for v := range ch {
			fmt.Println(v)
		}
	}()
	wg.Wait()
}

// 9.题目 ：编写一个程序，使用 sync.Mutex 来保护一个共享的计数器。启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
// 考察点 ： sync.Mutex 的使用、并发数据安全。
type SafeCounter struct {
	mu    sync.Mutex
	count int
}

func (sc *SafeCounter) Increment(m int) {
	sc.mu.Lock()
	defer sc.mu.Unlock()
	sc.count++
	fmt.Printf("goroutine %d incremented counter %d\n", m, sc.count)
}

func (sc *SafeCounter) GetCount() int {
	sc.mu.Lock()
	defer sc.mu.Unlock()
	return sc.count
}

func f9() {
	sc := SafeCounter{}
	var wg sync.WaitGroup

	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for j := 0; j < 1000; j++ {
				sc.Increment(i)
			}
		}()
	}

	wg.Wait()
}

// 10.题目 ：使用原子操作（ sync/atomic 包）实现一个无锁的计数器。启动10个协程，每个协程对计数器进行1000次递增操作，最后输出计数器的值。
// 考察点 ：原子操作、并发数据安全。

func f10() {
	var counter int64
	var wg sync.WaitGroup
	wg.Add(10)

	for i := 0; i < 10; i++ {
		go func() {
			defer wg.Done()
			for j := 0; j < 1000; j++ {
				atomic.AddInt64(&counter, 1)
			}
		}()
	}

	wg.Wait()
	fmt.Println("最终计算结果:", counter)
}

// 4.题目 ：设计一个任务调度器，接收一组任务（可以用函数表示），并使用协程并发执行这些任务，同时统计每个任务的执行时间。
// 考察点 ：协程原理、并发任务调度。
type Scheduler struct {
}

type Task struct {
	name string
	fn   func()
}

func (s *Scheduler) Run(tasks ...Task) {
	var wg sync.WaitGroup
	wg.Add(len(tasks))

	for _, task := range tasks {
		go func(task Task) {
			defer wg.Done()
			start := time.Now()
			task.fn()
			duration := time.Since(start)
			fmt.Printf("%s 任务执行时长: %d \n", task.name, duration.Round(time.Millisecond))
		}(task)
	}

	wg.Wait()
}

func tf1() {
	fmt.Println("tf1开始执行")
	time.Sleep(time.Second * 3)
	fmt.Println("tf1执行结束")
}

func tf2() {
	fmt.Println("tf2开始执行")
	time.Sleep(time.Second * 5)
	fmt.Println("tf2执行结束")
}

func f4() {
	sd := Scheduler{}
	task1 := Task{"TASK1", tf1}
	task2 := Task{"TASK2", tf2}
	sd.Run(task1, task2)
}

func main() {
	// 1.
	// num := 5
	// fmt.Println("修改前:", num) // 输出: 修改前: 5

	// addTen(&num)             // 传入 num 的地址
	// fmt.Println("修改后:", num) // 输出: 修改后: 15

	// 2.
	// nums := []int{1, 2, 3, 4, 5}
	// fmt.Println("修改前:", nums) // [1 2 3 4 5]

	// f2(&nums)
	// fmt.Println("修改后:", nums) // [2 4 6 8 10]

	// 3.
	// f3()

	// 5.
	// r := Rectangle{Width: 10, Height: 5}
	// PrintShapeInfo(r)
	// c := Circle{Radius: 5}
	// PrintShapeInfo(c)

	// 6.
	// p := Person{
	// 	Name: "Alice",
	// 	Age:  25,
	// }
	// el := Employee{
	// 	Ps: p,
	// 	ID: "E001",
	// }
	// el.PrintInfo()

	// 7.
	// f7()

	// 8.
	// f8()

	// 9.
	// f9()

	// 10.
	// f10()

	// 4.
	// f4()
}
