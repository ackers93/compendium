import { Controller } from "@hotwired/stimulus"
import * as d3 from "d3"

// Force-directed connection graph (Obsidian-style Map).
export default class extends Controller {
  static targets = ["canvas", "typeToggle", "empty"]
  static values = { graph: Object }

  connect() {
    this.hiddenTypes = new Set()
    this.visibleIds = new Set()
    this.dragged = false
    this.pendingFit = false
    this.resizeObserver = new ResizeObserver(() => this.resize())
    this.resizeObserver.observe(this.canvasSizeElement())
    this.render()
  }

  disconnect() {
    this.resizeObserver?.disconnect()
    this.simulation?.stop()
    this.simulation = null
    this.zoom = null
    this.svg = null
    this.zoomLayer = null
  }

  toggleType(event) {
    const type = event.currentTarget.dataset.type
    if (!type) return

    if (event.currentTarget.checked) {
      this.hiddenTypes.delete(type)
    } else {
      this.hiddenTypes.add(type)
    }
    this.applyVisibility({ fit: true })
  }

  // Size against the canvas wrap (visible map), not the outer panel+canvas shell.
  canvasSizeElement() {
    return this.canvasTarget.parentElement || this.canvasTarget
  }

  dimensions() {
    const rect = this.canvasSizeElement().getBoundingClientRect()
    return {
      width: Math.max(rect.width, 320),
      height: Math.max(rect.height, 240)
    }
  }

  render() {
    const svgEl = this.canvasTarget
    const { width, height } = this.dimensions()

    this.width = width
    this.height = height

    const svg = d3.select(svgEl)
    svg.selectAll("*").remove()
    svg.attr("viewBox", `0 0 ${width} ${height}`)
      .attr("width", "100%")
      .attr("height", "100%")

    this.svg = svg

    const graph = this.graphValue || { nodes: [], edges: [] }
    this.nodes = (graph.nodes || []).map((n) => ({ ...n }))
    this.links = (graph.edges || []).map((e) => ({
      ...e,
      source: e.source,
      target: e.target
    }))

    if (this.nodes.length === 0) return

    const g = svg.append("g").attr("class", "graph-map__zoom")
    this.zoomLayer = g

    this.link = g.append("g")
      .attr("class", "graph-map__links")
      .selectAll("line")
      .data(this.links)
      .join("line")
      .attr("class", "graph-map__link")

    this.node = g.append("g")
      .attr("class", "graph-map__nodes")
      .selectAll("g")
      .data(this.nodes)
      .join("g")
      .attr("class", (d) => `graph-map__node graph-map__node--${this.typeClass(d.type)}`)
      .style("cursor", "pointer")
      .call(this.dragBehavior())
      .on("click", (event, d) => {
        if (this.dragged || event.defaultPrevented) return
        if (d.url) {
          if (window.Turbo) {
            window.Turbo.visit(d.url)
          } else {
            window.location.href = d.url
          }
        }
      })

    this.node.append("circle")
      .attr("r", (d) => d.size || 6)
      .attr("class", "graph-map__dot")

    this.node.append("title").text((d) => d.label || d.id)

    this.node.append("text")
      .attr("class", "graph-map__label")
      .attr("dy", (d) => (d.size || 6) + 10)
      .attr("text-anchor", "middle")
      .text((d) => this.shortLabel(d.label))

    this.pendingFit = true
    this.simulation = d3.forceSimulation(this.nodes)
      .force("link", d3.forceLink(this.links).id((d) => d.id).distance(56).strength(0.4))
      .force("charge", d3.forceManyBody().strength(-120))
      .force("center", d3.forceCenter(width / 2, height / 2))
      .force("collision", d3.forceCollide().radius((d) => (d.size || 6) + 8))
      .on("tick", () => this.ticked())
      .on("end", () => this.onSimulationEnd())

    this.zoom = d3.zoom()
      .scaleExtent([0.2, 4])
      .on("zoom", (event) => {
        g.attr("transform", event.transform)
      })

    svg.call(this.zoom)
    this.applyVisibility({ fit: false })
  }

  resize() {
    if (!this.simulation) return
    const { width, height } = this.dimensions()
    if (Math.abs(width - this.width) < 8 && Math.abs(height - this.height) < 8) return

    this.width = width
    this.height = height
    d3.select(this.canvasTarget).attr("viewBox", `0 0 ${width} ${height}`)
    this.simulation.force("center", d3.forceCenter(width / 2, height / 2))
    this.pendingFit = true
    this.simulation.alpha(0.3).restart()
  }

  onSimulationEnd() {
    if (!this.pendingFit) return
    this.pendingFit = false
    this.fitToVisibleNodes()
  }

  ticked() {
    this.link
      .attr("x1", (d) => d.source.x)
      .attr("y1", (d) => d.source.y)
      .attr("x2", (d) => d.target.x)
      .attr("y2", (d) => d.target.y)

    this.node.attr("transform", (d) => `translate(${d.x},${d.y})`)
  }

  applyVisibility({ fit = false } = {}) {
    if (!this.node) return

    const hidden = this.hiddenTypes
    const typedVisible = new Set(
      this.nodes.filter((n) => !hidden.has(n.type)).map((n) => n.id)
    )

    // Only keep nodes that still have an edge to another typed-visible node.
    const connectedVisible = new Set()
    this.links.forEach((d) => {
      const s = typeof d.source === "object" ? d.source.id : d.source
      const t = typeof d.target === "object" ? d.target.id : d.target
      if (typedVisible.has(s) && typedVisible.has(t)) {
        connectedVisible.add(s)
        connectedVisible.add(t)
      }
    })

    this.visibleIds = connectedVisible

    this.node.style("display", (d) => (connectedVisible.has(d.id) ? null : "none"))
    this.link.style("display", (d) => {
      const s = typeof d.source === "object" ? d.source.id : d.source
      const t = typeof d.target === "object" ? d.target.id : d.target
      return connectedVisible.has(s) && connectedVisible.has(t) ? null : "none"
    })

    if (this.hasEmptyTarget) {
      // Show empty state when nothing is visible under the current filters.
      this.emptyTarget.hidden = connectedVisible.size > 0
    }

    if (fit && connectedVisible.size > 0) {
      // Simulation may still be cooling after a resize; otherwise fit immediately.
      if (this.simulation && this.simulation.alpha() > 0.02) {
        this.pendingFit = true
      } else {
        this.fitToVisibleNodes({ animate: true })
      }
    }
  }

  fitToVisibleNodes({ animate = false } = {}) {
    if (!this.zoom || !this.svg || !this.nodes?.length) return

    const visible = this.nodes.filter((n) => this.visibleIds.has(n.id) && n.x != null && n.y != null)
    if (visible.length === 0) return

    let minX = Infinity
    let minY = Infinity
    let maxX = -Infinity
    let maxY = -Infinity

    visible.forEach((n) => {
      const r = (n.size || 6) + 4
      // Labels sit below the dot; include a bit of vertical room.
      minX = Math.min(minX, n.x - r)
      minY = Math.min(minY, n.y - r)
      maxX = Math.max(maxX, n.x + r)
      maxY = Math.max(maxY, n.y + r + 14)
    })

    const boundsWidth = Math.max(maxX - minX, 1)
    const boundsHeight = Math.max(maxY - minY, 1)
    const padding = 36
    const scale = Math.min(
      4,
      Math.max(
        0.2,
        0.9 * Math.min(
          (this.width - padding * 2) / boundsWidth,
          (this.height - padding * 2) / boundsHeight
        )
      )
    )
    const transform = d3.zoomIdentity
      .translate(this.width / 2, this.height / 2)
      .scale(scale)
      .translate(-(minX + maxX) / 2, -(minY + maxY) / 2)

    const selection = this.svg
    if (animate) {
      selection.transition().duration(350).call(this.zoom.transform, transform)
    } else {
      selection.call(this.zoom.transform, transform)
    }
  }

  dragBehavior() {
    const simulation = () => this.simulation

    return d3.drag()
      .on("start", (event, d) => {
        this.dragged = false
        if (!event.active) simulation().alphaTarget(0.3).restart()
        d.fx = d.x
        d.fy = d.y
      })
      .on("drag", (event, d) => {
        this.dragged = true
        d.fx = event.x
        d.fy = event.y
      })
      .on("end", (event, d) => {
        if (!event.active) simulation().alphaTarget(0)
        d.fx = null
        d.fy = null
        // Allow click shortly after a tiny drag; clear flag next tick for real drags
        if (this.dragged) {
          requestAnimationFrame(() => { this.dragged = false })
        }
      })
  }

  typeClass(type) {
    return String(type || "")
      .replace(/([a-z])([A-Z])/g, "$1-$2")
      .replace(/_/g, "-")
      .toLowerCase()
  }

  shortLabel(label) {
    if (!label) return ""
    return label.length > 28 ? `${label.slice(0, 26)}…` : label
  }
}
