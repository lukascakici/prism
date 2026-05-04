// Prism C++ sample.
//
// Exercises:
//   - templates, concepts, constexpr
//   - namespaces, classes, inheritance, virtual / override / final
//   - lambdas, std::optional, structured bindings
//   - raw string literals R"(...)" and string suffixes
//   - preprocessor directives
//   - operator overloading

#include <algorithm>
#include <concepts>
#include <iostream>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace prism {

/* -------------------------------------------------------------------------
 * Concepts
 * ------------------------------------------------------------------------- */

template <typename T>
concept Numeric = std::integral<T> || std::floating_point<T>;

/* -------------------------------------------------------------------------
 * Generic geometry types
 * ------------------------------------------------------------------------- */

template <Numeric T = double>
struct Point {
    T x{};
    T y{};

    constexpr Point() noexcept = default;
    constexpr Point(T x_, T y_) noexcept : x{x_}, y{y_} {}

    constexpr T distance_to(const Point &other) const noexcept {
        const auto dx = x - other.x;
        const auto dy = y - other.y;
        return static_cast<T>(std::hypot(dx, dy));
    }

    constexpr bool operator==(const Point &) const noexcept = default;
};

/* -------------------------------------------------------------------------
 * Classic OO with virtual dispatch
 * ------------------------------------------------------------------------- */

class Shape {
public:
    virtual ~Shape() = default;
    [[nodiscard]] virtual double area() const noexcept = 0;
    [[nodiscard]] virtual std::string_view kind() const noexcept = 0;
};

class Circle final : public Shape {
public:
    explicit Circle(double r) noexcept : radius_{r} {}

    double area() const noexcept override { return 3.14159265358979 * radius_ * radius_; }
    std::string_view kind() const noexcept override { return "circle"; }

private:
    double radius_;
};

/* -------------------------------------------------------------------------
 * Helpers — strings, optionals, lambdas
 * ------------------------------------------------------------------------- */

constexpr std::string_view greet_template = R"(Hello, {}!
Welcome to Prism.
Mask = 0x{:08X})";

template <Numeric T>
[[nodiscard]] constexpr std::optional<T> safe_div(T numer, T denom) noexcept {
    if (denom == T{0}) return std::nullopt;
    return numer / denom;
}

}  // namespace prism

int main() {
    using namespace prism;

    constexpr Point<double> a{1.0, 2.0};
    constexpr Point<double> b{4.0, 6.0};
    static_assert(a.distance_to(b) > 4.9);

    std::vector<std::unique_ptr<Shape>> shapes;
    shapes.emplace_back(std::make_unique<Circle>(2.5));

    auto total_area = std::transform_reduce(
        shapes.begin(), shapes.end(), 0.0, std::plus<>{},
        [](const auto &s) { return s->area(); });

    std::cout << "shapes=" << shapes.size()
              << ", area=" << total_area
              << ", kind=" << shapes.front()->kind() << '\n';

    if (auto q = safe_div(10.0, 0.0); !q.has_value()) {
        std::cerr << "division by zero\n";
    }

    constexpr unsigned MASK = 0xDEAD'BEEFu;
    auto [w, h] = std::pair{1920u, 1080u};
    std::cout << "MASK=" << std::hex << MASK << ", " << std::dec << w << 'x' << h << '\n';
    return 0;
}
